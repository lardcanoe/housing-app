defmodule HousingApp.Management.Form do
  @moduledoc false

  use Ash.Resource, data_layer: AshPostgres.DataLayer, extensions: [AshAdmin.Api], authorizers: [Ash.Policy.Authorizer]

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

    attribute :json_schema, :string do
      allow_nil? false
    end

    attribute :version, :integer do
      default 1
      allow_nil? false
    end

    attribute :type, :string do
      constraints min_length: 1, trim?: true
      default ""
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

    has_many :submissions, HousingApp.Management.FormSubmission do
      source_attribute :id
      destination_attribute :form_id
    end
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
    table "forms"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :new do
      accept [:name, :description, :json_schema, :type]

      argument :tenant_id, :uuid do
        allow_nil? false
      end

      change manage_relationship(:tenant_id, :tenant, type: :append_and_remove)
    end

    read :list do
      prepare build(
                select: [:id, :name, :type, :description, :status],
                load: [:count_of_submissions],
                sort: [:name]
              )

      filter expr(is_nil(archived_at))
    end

    read :list_approved do
      prepare build(
                select: [:id, :name, :type, :description, :status],
                load: [:count_of_submissions],
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
                select: [:id, :name, :type, :description, :status],
                load: [:count_of_submissions],
                sort: [:name]
              )

      filter expr(type == ^arg(:type) and is_nil(archived_at))
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true

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
  end

  code_interface do
    define_for HousingApp.Management

    define :list
    define :list_approved
    define :list_by_type, args: [:type]
    define :get_by_id, args: [:id]
    define :get_types
  end

  validations do
    validate {HousingApp.Validations.IsJsonSchema, attribute: :json_schema}
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
