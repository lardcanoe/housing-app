defmodule HousingApp.Management.Profile do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource, AshAdmin.Api],
    authorizers: [Ash.Policy.Authorizer]

  admin do
    show?(true)
  end

  postgres do
    table "profiles"
    repo HousingApp.Repo
  end

  multitenancy do
    strategy :context
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id
  end

  relationships do
    belongs_to :user_tenant, HousingApp.Accounts.UserTenant do
      api HousingApp.Accounts
      attribute_writable? true
      allow_nil? false
    end
  end

  identities do
    identity :unique_user_tenant, [:user_tenant_id]
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
end
