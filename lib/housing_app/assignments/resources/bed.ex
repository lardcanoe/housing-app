defmodule HousingApp.Assignments.Bed do
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

    attribute :available_at, :utc_datetime_usec do
      allow_nil? true
    end

    attribute :data, :map do
      default %{}
      allow_nil? false
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

  relationships do
    # Tenant is duplicate data, but makes it safer and easier to do data dumps
    belongs_to :tenant, HousingApp.Accounts.Tenant do
      api HousingApp.Accounts
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :room, HousingApp.Assignments.Room do
      attribute_writable? true
      allow_nil? false
    end
  end

  policies do
    bypass always() do
      authorize_if HousingApp.Checks.IsPlatformAdmin
      authorize_if HousingApp.Checks.IsTenantAdmin
    end

    policy action_type(:read) do
      authorize_if always()
    end
  end

  postgres do
    table "beds"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :new do
      accept [:name, :room_id]
      change set_attribute(:tenant_id, actor(:tenant_id))
    end

    read :list do
      prepare build(load: [room: [:building]])
      filter expr(is_nil(archived_at))
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      prepare build(load: [room: [:building]])

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
    identity :unique_by_room_and_name, [:room_id, :name]
  end

  multitenancy do
    strategy :context
  end
end
