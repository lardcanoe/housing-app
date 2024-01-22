defmodule HousingApp.Management.UserTenantRole do
  @moduledoc false
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    # nil means this role never expires
    attribute :start_at, :date
    attribute :end_at, :date

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :archived_at, :utc_datetime_usec do
      private? true
      allow_nil? true
    end
  end

  relationships do
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

    belongs_to :role, HousingApp.Management.Role do
      attribute_writable? true
      allow_nil? false
    end

    # NOTE: If set, then manages start/end dates. If nil, then we have a custom time range for this role
    belongs_to :time_period, HousingApp.Management.TimePeriod do
      attribute_writable? true
    end

    has_many :role_queries, HousingApp.Assignments.RoleQuery do
      api HousingApp.Assignments
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
    table "user_tenant_roles"
    repo HousingApp.Repo

    custom_indexes do
      index [:user_tenant_id]
    end
  end

  actions do
    defaults [:read, :create, :update]

    create :new do
      accept [:role_id, :time_period_id, :start_at, :end_at, :user_tenant_id, :tenant_id]
      change set_attribute(:tenant_id, actor(:tenant_id))
    end

    read :list do
      prepare build(load: [:role, :time_period, user_tenant: [:user]])
      filter expr(is_nil(archived_at))
    end

    read :list_my_active do
      prepare build(load: [:role])

      filter expr(
               user_tenant_id == ^actor(:id) and
                 is_nil(archived_at) and
                 (is_nil(end_at) or end_at > ^Date.utc_today()) and
                 (is_nil(start_at) or start_at <= ^Date.utc_today())
             )
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      prepare build(load: [:role, role_queries: [:common_query]])
      get? true
      filter expr(id == ^arg(:id) and is_nil(archived_at))
    end

    destroy :archive do
      primary? true
      soft? true
      change set_attribute(:archived_at, &DateTime.utc_now/0)
    end
  end

  code_interface do
    define_for HousingApp.Management

    define :new
    define :list
    define :list_my_active
    define :get_by_id, args: [:id]
  end

  # FUTURE: validate all date permutations
  validations do
    # validate compare(:end_at, greater_than: :start_at)
    # FUTURE: , message: "must be a date after %{start_at}."
  end

  multitenancy do
    strategy :context
  end
end
