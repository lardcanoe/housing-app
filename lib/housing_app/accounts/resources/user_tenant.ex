defmodule HousingApp.Accounts.UserTenant do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :user_type, :atom do
      constraints one_of: [:user, :staff, :admin]
      default :user
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :archived_at, :utc_datetime_usec do
      allow_nil? true
    end
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

    read :get_for_tenant do
      argument :tenant_id, :uuid do
        allow_nil? false
      end

      get? true

      prepare build(load: [:user, :tenant])

      filter expr(user_id == ^actor(:id) and tenant_id == ^arg(:tenant_id) and is_nil(archived_at))
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true

      prepare build(load: [:user, :tenant])

      filter expr(user_id == ^actor(:id) and id == ^arg(:id) and is_nil(archived_at))
    end

    read :get_default do
      get? true

      prepare build(limit: 1, sort: [created_at: :asc], load: [:user, :tenant])

      filter expr(user_id == ^actor(:id) and is_nil(archived_at))
    end

    # No actor set, and no auth performed
    read :find_for_api do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true

      prepare build(load: [:user, :tenant])

      filter expr(id == ^arg(:id) and is_nil(archived_at))
    end
  end

  code_interface do
    define_for HousingApp.Accounts

    define :get_default
    define :get_for_tenant, args: [:tenant_id]
    define :get_by_id, args: [:id]
    define :find_for_api, args: [:id]
  end

  identities do
    identity :unique_user_and_tenant, [:user_id, :tenant_id]
  end
end
