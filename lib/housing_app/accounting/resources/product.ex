defmodule HousingApp.Accounting.Product do
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

    attribute :description, :string do
      constraints trim?: true
      default ""
    end

    attribute :rate, :decimal do
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
      private? true
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
  end

  policies do
    bypass always() do
      authorize_if HousingApp.Checks.IsPlatformAdmin
      authorize_if HousingApp.Checks.IsTenantAdmin
    end
  end

  postgres do
    table "products"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update]

    create :new do
      accept [:name, :description, :rate]
      change set_attribute(:tenant_id, actor(:tenant_id))
    end

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

    destroy :archive do
      primary? true
      soft? true
      change set_attribute(:archived_at, &DateTime.utc_now/0)
    end
  end

  code_interface do
    define_for HousingApp.Accounting

    define :new
    define :list
    define :get_by_id, args: [:id]
  end

  identities do
    identity :unique_by_name, [:name]
  end

  multitenancy do
    strategy :context
  end
end
