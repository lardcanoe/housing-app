defmodule HousingApp.Management.Profile do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource, AshAdmin.Api],
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    # Used for things like "student, parent, RA, etc"
    # These are applicable based on the type of organization that the tenant is
    attribute :roles, {:array, :string} do
      default []
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
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

    belongs_to :user_tenant, HousingApp.Accounts.UserTenant do
      api HousingApp.Accounts
      attribute_writable? true
      allow_nil? false
    end
  end

  policies do
    bypass always() do
      authorize_if HousingApp.Checks.IsPlatformAdmin
    end

    policy action_type(:create) do
      authorize_if HousingApp.Checks.IsTenantAdmin
    end

    policy action_type(:read) do
      authorize_if HousingApp.Checks.IsTenantAdmin
      authorize_if relates_to_actor_via(:user_tenant)
    end
  end

  postgres do
    table "profiles"
    repo HousingApp.Repo

    custom_indexes do
      index [:roles], using: "GIN"
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  identities do
    identity :unique_user_tenant, [:user_tenant_id]
  end

  multitenancy do
    strategy :context
  end
end
