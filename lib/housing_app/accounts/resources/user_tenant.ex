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

    attribute :api_key, :string, sensitive?: true

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :archived_at, :utc_datetime_usec do
      private? true
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

    has_many :user_tenant_roles, HousingApp.Management.UserTenantRole do
      api HousingApp.Management
      source_attribute :id
      destination_attribute :user_tenant_id
    end
  end

  policies do
    bypass always() do
      authorize_if HousingApp.Checks.IsPlatformAdmin
    end

    policy action_type(:read) do
      authorize_if HousingApp.Checks.IsTenantAdmin
      # TODO: Fix, but relates_to_actor_via(:user) breaks joins from Roommates. This was a nasty subtle error.
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:update) do
      authorize_if HousingApp.Checks.IsTenantAdmin
    end

    policy action_type(:generate_api_key) do
      authorize_if HousingApp.Checks.IsTenantAdmin
    end
  end

  postgres do
    table "user_tenants"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :destroy]

    update :update do
      argument :user_tenant_roles, {:array, :map}

      change manage_relationship(:user_tenant_roles, type: :direct_control)
    end

    read :get_mine_for_tenant do
      argument :tenant_id, :uuid do
        allow_nil? false
      end

      get? true

      prepare build(load: [:user, :tenant])

      filter expr(user_id == ^actor(:id) and tenant_id == ^arg(:tenant_id) and is_nil(archived_at))
    end

    read :get_for_user_of_my_tenant do
      argument :user_id, :uuid do
        allow_nil? false
      end

      get? true

      filter expr(user_id == ^arg(:user_id) and tenant_id == ^actor(:tenant_id) and is_nil(archived_at))
    end

    read :get_user_by_email do
      argument :email, :string do
        allow_nil? false
      end

      get? true

      prepare build(load: [:user, :tenant])

      filter expr(
               tenant_id == ^actor(:tenant_id) and user_type == :user and user.email == ^arg(:email) and
                 is_nil(archived_at)
             )
    end

    read :find_for_my_user do
      prepare build(load: [:user, :tenant])
      filter expr(user_id == ^actor(:id) and is_nil(archived_at))
    end

    read :list_staff do
      prepare build(load: [:user, :user_tenant_roles])

      filter expr(tenant_id == ^actor(:tenant_id) and user_type in [:staff, :admin])
    end

    read :list_students do
      prepare build(load: [:user])

      filter expr(tenant_id == ^actor(:tenant_id) and user_type == :user)
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
    read :get_by_api_key do
      argument :key, :string do
        allow_nil? false
      end

      get? true

      prepare build(load: [:user, :tenant])

      filter expr(api_key == ^arg(:key) and is_nil(archived_at))
    end

    update :generate_api_key do
      accept []
      change set_attribute(:api_key, &HousingApp.Utils.Random.Token.generate/0)
    end

    update :revoke_api_key do
      accept []
      change set_attribute(:api_key, nil)
    end
  end

  code_interface do
    define_for HousingApp.Accounts

    define :get_default
    define :get_mine_for_tenant, args: [:tenant_id]
    define :get_user_by_email, args: [:email]
    define :get_for_user_of_my_tenant, args: [:user_id]
    define :find_for_my_user
    define :list_staff
    define :list_students
    define :get_by_id, args: [:id]
    define :get_by_api_key, args: [:key]
    define :generate_api_key
    define :revoke_api_key
  end

  identities do
    identity :unique_user_and_tenant, [:user_id, :tenant_id]

    identity :unique_api_key, [:api_key]
  end
end
