defmodule HousingApp.Management.Application do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api],
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub]

  require Ash.Query

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      constraints min_length: 1, trim?: true
      allow_nil? false
    end

    attribute :description, :string do
      default ""
      allow_nil? false
    end

    attribute :status, :atom do
      constraints one_of: [:draft, :approved, :archived]
      default :draft
      allow_nil? false
    end

    attribute :type, :string do
      constraints min_length: 1, trim?: true
      default ""
      allow_nil? false
    end

    attribute :submission_type, :atom do
      constraints one_of: [:once, :many]
      default :once
      allow_nil? false
    end

    attribute :steps, {:array, HousingApp.Management.ApplicationStep} do
      default []
      allow_nil? false
    end

    attribute :conditions, {:array, HousingApp.Management.ApplicationCondition} do
      default []
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :archived_at, :utc_datetime_usec do
      private? true
      allow_nil? true
    end
  end

  admin do
    show?(true)
  end

  relationships do
    # Tenant is duplicate data, but makes it safer and easier to do data dumps
    belongs_to :tenant, HousingApp.Accounts.Tenant do
      api HousingApp.Accounts
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :form, HousingApp.Management.Form do
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :time_period, HousingApp.Management.TimePeriod do
      attribute_writable? true
      # FUTURE:      allow_nil? false
    end

    has_many :submissions, HousingApp.Management.ApplicationSubmission do
      source_attribute :id
      destination_attribute :application_id
    end
  end

  pub_sub do
    module Phoenix.PubSub
    name HousingApp.PubSub
    prefix "application"
    broadcast_type :broadcast

    publish :new, [[:_tenant], ["created"]], event: "application-created"
    publish :update, [[:_tenant], ["updated"]], event: "application-updated"
  end

  policies do
    bypass always() do
      authorize_if HousingApp.Checks.IsPlatformAdmin
      authorize_if HousingApp.Checks.IsTenantAdmin
    end

    policy action_type(:read) do
      authorize_if always()
    end
  end

  postgres do
    table "applications"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update]

    create :new do
      accept [:name, :description, :form_id, :time_period_id, :status, :type, :submission_type, :steps, :conditions]

      change set_attribute(:tenant_id, actor(:tenant_id))
    end

    create :copy do
      argument :source, :map do
        allow_nil? false
      end

      change fn changeset, context ->
        Ash.Changeset.change_attributes(
          changeset,
          HousingApp.Utils.Forms.copy_resource(__MODULE__, changeset.arguments.source)
        )
      end
    end

    read :list do
      prepare build(
                select: [:id, :name, :type, :submission_type, :description, :status, :form_id],
                load: [:form, :time_period, :count_of_submissions],
                sort: [:name]
              )

      filter expr(is_nil(archived_at))
    end

    read :list_approved do
      prepare build(
                select: [:id, :name, :type, :submission_type, :description, :status, :form_id, :conditions],
                load: [:form],
                sort: [:name]
              )

      filter expr(status == :approved and is_nil(archived_at))
    end

    # By type, and optional status
    read :list_by_type do
      argument :type, :string do
        constraints min_length: 1, trim?: true
        allow_nil? false
      end

      argument :status, :atom do
        constraints one_of: [:draft, :approved, :archived]
        allow_nil? true
      end

      prepare build(
                select: [:id, :name, :type, :submission_type, :description, :status, :form_id],
                load: [:form, :time_period, :count_of_submissions],
                sort: [:name]
              )

      filter expr(
               if is_nil(^arg(:status)) do
                 type == ^arg(:type) and is_nil(archived_at)
               else
                 type == ^arg(:type) and status == ^arg(:status) and is_nil(archived_at)
               end
             )
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true

      prepare build(load: [:form, :time_period, :count_of_submissions, steps: [:form], conditions: [:common_query]])

      filter expr(id == ^arg(:id) and is_nil(archived_at))
    end

    action :get_types, {:array, :string} do
      run fn input, context ->
        types =
          __MODULE__
          |> Ash.Query.for_read(:read, %{select: [:type]}, actor: context.actor, tenant: input.tenant)
          |> Ash.Query.filter(is_nil(archived_at))
          |> HousingApp.Management.read!()
          |> Enum.map(& &1.type)
          |> Enum.reject(&(is_nil(&1) || &1 == ""))
          |> Enum.uniq()
          |> Enum.sort()

        {:ok, types}
      end
    end

    destroy :archive do
      primary? true
      soft? true
      change set_attribute(:archived_at, &DateTime.utc_now/0)
    end
  end

  code_interface do
    define_for HousingApp.Management

    define :list
    define :list_approved
    define :list_by_type, args: [:type, {:optional, :status}]
    define :get_by_id, args: [:id]
    define :get_types
    define :copy, args: [:source]
  end

  aggregates do
    count :count_of_submissions, :submissions do
      filter expr(status == :completed and is_nil(archived_at))
    end
  end

  multitenancy do
    strategy :context
  end
end
