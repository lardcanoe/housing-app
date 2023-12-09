defmodule HousingApp.Assignments.Room do
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

    attribute :floor, :integer do
      default 1
      allow_nil? false
    end

    attribute :block, :string do
      constraints trim?: true
      default ""
      allow_nil? false
    end

    attribute :max_capacity, :integer do
      default 0
      allow_nil? false
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

    belongs_to :building, HousingApp.Assignments.Building do
      attribute_writable? true
      allow_nil? false
    end
  end

  policies do
    bypass always() do
      authorize_if HousingApp.Checks.IsPlatformAdmin
      authorize_if HousingApp.Checks.IsTenantAdmin
    end
  end

  postgres do
    table "rooms"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :list do
      filter expr(is_nil(archived_at))
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
    define_for HousingApp.Assignments

    define :list
    define :get_by_id, args: [:id]
  end

  identities do
    identity :unique_by_building_and_name, [:building_id, :name]
  end

  multitenancy do
    strategy :context
  end
end
