defmodule HousingApp.Assignments.RoleQuery do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id

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

    belongs_to :user_tenant_role, HousingApp.Management.UserTenantRole do
      api HousingApp.Management
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :common_query, HousingApp.Management.CommonQuery do
      api HousingApp.Management
      attribute_writable? true
      allow_nil? false
    end
  end

  postgres do
    table "role_queries"
    repo HousingApp.Repo

    custom_indexes do
      index [:user_tenant_role_id]
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :new do
      accept [:user_tenant_role_id, :common_query_id]
      change set_attribute(:tenant_id, actor(:tenant_id))
    end

    read :list do
      prepare build(load: [:common_query, user_tenant_role: [:role, :time_period, user_tenant: [:user]]])
      filter expr(is_nil(archived_at))
    end

    # TODO: Only an owner or member should be able to read
    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true

      filter expr(id == ^arg(:id) and is_nil(archived_at))
    end
  end

  code_interface do
    define_for HousingApp.Assignments

    define :new
    define :list
    define :get_by_id, args: [:id]
  end

  identities do
    identity :unique_by_role_and_query, [:user_tenant_role_id, :common_query_id]
  end

  multitenancy do
    strategy :context
  end
end
