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

  multitenancy do
    strategy :context
  end
end
