defmodule HousingApp.Accounts.UserTenant do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource],
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :role, :atom do
      constraints one_of: [:user, :staff, :admin]
      default :user
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, HousingApp.Accounts.User do
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :tenant, HousingApp.Accounts.Tenant do
      attribute_writable? true
      allow_nil? false
    end
  end

  policies do
    bypass always() do
      authorize_if HousingApp.Checks.IsPlatformAdmin
    end

    policy action_type(:read) do
      authorize_if HousingApp.Checks.IsTenantAdmin
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:update) do
      authorize_if HousingApp.Checks.IsTenantAdmin
    end
  end

  postgres do
    table "user_tenants"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  identities do
    identity :unique_user_and_tenant, [:user_id, :tenant_id]
  end
end
