defmodule HousingApp.Management.Profile do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource, AshAdmin.Api],
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :data, :map do
      default %{}
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
      index [:data], using: "GIN"
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :list do
      prepare build(load: [user_tenant: [:user]])
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true

      prepare build(load: [user_tenant: [:user]])

      filter expr(id == ^arg(:id))
    end
  end

  code_interface do
    define_for HousingApp.Management

    define :list
    define :get_by_id, args: [:id]
  end

  identities do
    identity :unique_user_tenant, [:user_tenant_id]
  end

  multitenancy do
    strategy :context
  end
end
