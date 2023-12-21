defmodule HousingApp.Management.Application do
  @moduledoc false

  require Ash.Query

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api],
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub]

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

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :archived_at, :utc_datetime_usec do
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
    module HousingAppWeb.Endpoint
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
    defaults [:create, :read, :update, :destroy]

    create :new do
      accept [:name, :description, :form_id, :status, :type, :submission_type]

      change set_attribute(:tenant_id, actor(:tenant_id))
    end

    read :list do
      prepare build(
                select: [:id, :name, :type, :submission_type, :description, :status, :form_id],
                load: [:form, :count_of_submissions],
                sort: [:name]
              )

      filter expr(is_nil(archived_at))
    end

    read :list_approved do
      prepare build(
                select: [:id, :name, :type, :submission_type, :description, :status, :form_id],
                load: [:form],
                sort: [:name]
              )

      filter expr(status == :approved and is_nil(archived_at))
    end

    read :list_by_type do
      argument :type, :string do
        constraints min_length: 1, trim?: true
        allow_nil? false
      end

      prepare build(
                select: [:id, :name, :type, :submission_type, :description, :status, :form_id],
                load: [:form, :count_of_submissions],
                sort: [:name]
              )

      filter expr(type == ^arg(:type) and is_nil(archived_at))
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true

      prepare build(load: [:form, :count_of_submissions])

      filter expr(id == ^arg(:id) and is_nil(archived_at))
    end

    action :get_types, {:array, :string} do
      run fn input, context ->
        types =
          __MODULE__
          |> Ash.Query.for_read(:read, %{select: [:type]}, actor: context.actor)
          |> Ash.Query.filter(is_nil(archived_at))
          |> HousingApp.Management.read!()
          |> Enum.map(& &1.type)
          |> Enum.reject(&(is_nil(&1) || &1 == ""))
          |> Enum.uniq()
          |> Enum.sort()

        {:ok, types}
      end
    end
  end

  code_interface do
    define_for HousingApp.Management

    define :list
    define :list_approved
    define :list_by_type, args: [:type]
    define :get_by_id, args: [:id]
    define :get_types
  end

  aggregates do
    count :count_of_submissions, :submissions do
      filter expr(is_nil(archived_at))
    end
  end

  multitenancy do
    strategy :context
  end
end
