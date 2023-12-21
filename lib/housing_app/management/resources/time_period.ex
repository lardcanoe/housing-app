defmodule HousingApp.Management.TimePeriod do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api],
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      constraints min_length: 1, trim?: true
      allow_nil? false
    end

    attribute :start_at, :date do
      allow_nil? false
    end

    attribute :end_at, :date do
      allow_nil? false
    end

    attribute :status, :atom do
      constraints one_of: [:pending, :active, :archived]
      default :pending
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  admin do
    show?(true)
  end

  relationships do
    belongs_to :tenant, HousingApp.Accounts.Tenant do
      api HousingApp.Accounts
      attribute_writable? true
      allow_nil? false
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
    table "time_periods"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :new do
      accept [:name, :start_at, :end_at, :status]
      change set_attribute(:tenant_id, actor(:tenant_id))
    end

    read :list do
      prepare build(sort: [start_at: :desc, name: :asc])
    end
  end

  code_interface do
    define_for HousingApp.Management

    define :new
    define :list
  end

  identities do
    identity :unique_name, [:name]
  end

  validations do
    validate compare(:end_at, greater_than: :start_at)
    # FUTURE: , message: "must be a date after %{start_at}."
  end

  multitenancy do
    strategy :context
  end
end
