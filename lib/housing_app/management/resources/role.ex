defmodule HousingApp.Management.Role do
  @moduledoc false
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      constraints min_length: 1, trim?: true
      allow_nil? false
    end

    attribute :description, :string do
      default ""
      allow_nil? true
    end

    # Can be empty, which basically treats the role as a "tag"
    # e.g. has_role?("RA")
    attribute :permissions, {:array, HousingApp.Management.Permission} do
      default []
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :archived_at, :utc_datetime_usec do
      allow_nil? true
    end
  end

  relationships do
    belongs_to :tenant, HousingApp.Accounts.Tenant do
      api HousingApp.Accounts
      attribute_writable? true
      allow_nil? false
    end
  end

  policies do
    bypass always() do
      authorize_if HousingApp.Checks.IsPlatformAdmin
      authorize_if HousingApp.Checks.IsTenantAdmin
      authorize_if action_type(:read)
    end
  end

  postgres do
    table "roles"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :list do
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true

      filter expr(id == ^arg(:id) and is_nil(archived_at))
    end
  end

  code_interface do
    define_for HousingApp.Management

    define :list
    define :get_by_id, args: [:id]
  end

  identities do
    identity :unique_by_name, [:name]
  end

  multitenancy do
    strategy :context
  end
end
