defmodule HousingApp.Management.Profile do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api, AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :_data, :map do
      default %{}
      allow_nil? false
      sensitive? true
      private? true
      source :data
    end

    # FUTURE: This is not ideal, since we load a large map from the db twice
    attribute :sanitized_data, :map do
      default %{}
      allow_nil? false
      sensitive? true
      source :data
    end

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :archived_at, :utc_datetime_usec do
      allow_nil? true
    end
  end

  admin do
    show?(true)
  end

  json_api do
    type "profile"

    routes do
      base("/profiles")

      get(:read)
      index :read
      post(:create)
    end
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

    policy action_type(:update) do
      authorize_if HousingApp.Checks.IsTenantAdmin
      # TODO: This is a hack to allow users to update their own profiles
      authorize_if always()
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
    # No :update because we need :submit logic to deal with merging santized data
    defaults [:create, :destroy]

    read :read do
      primary? true
      prepare &HousingApp.Checks.FilterData.filter_records/2
      filter expr(is_nil(archived_at))
    end

    read :list do
      prepare build(load: [user_tenant: [:user]])
      prepare &HousingApp.Checks.FilterData.filter_records/2
      filter expr(is_nil(archived_at))
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true
      prepare build(load: [user_tenant: [:user]])
      prepare &HousingApp.Checks.FilterData.filter_records/2
      filter expr(id == ^arg(:id) and is_nil(archived_at))
    end

    read :match_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      # NOTE: We don't filter, since only :id is selected
      prepare build(select: [:id])
      get? true
      filter expr(id == ^arg(:id) and is_nil(archived_at))
    end

    read :get_by_user_tenant do
      argument :user_tenant_id, :uuid do
        allow_nil? false
      end

      get? true
      prepare &HousingApp.Checks.FilterData.filter_records/2
      filter expr(user_tenant_id == ^arg(:user_tenant_id) and is_nil(archived_at))
    end

    read :get_mine do
      get? true
      prepare &HousingApp.Checks.FilterData.filter_records/2
      filter expr(user_tenant_id == ^actor(:id) and is_nil(archived_at))
    end

    read :get_my_id do
      get? true
      prepare build(select: [:id])
      filter expr(user_tenant_id == ^actor(:id) and is_nil(archived_at))
    end

    update :submit do
      accept [:sanitized_data]

      change fn changset, _context ->
        changset
        |> Ash.Changeset.before_action(&HousingApp.Checks.FilterData.merge_sanitized_data/1)
        |> Ash.Changeset.after_action(fn _changeset, record ->
          {:ok, HousingApp.Checks.FilterData.filter_record(record)}
        end)
      end
    end
  end

  code_interface do
    define_for HousingApp.Management

    define :list
    define :get_mine
    define :get_my_id
    define :get_by_id, args: [:id]
    define :match_by_id, args: [:id]
    define :get_by_user_tenant, args: [:user_tenant_id]
    define :submit
  end

  identities do
    identity :unique_user_tenant, [:user_tenant_id]
  end

  multitenancy do
    strategy :context
  end
end
