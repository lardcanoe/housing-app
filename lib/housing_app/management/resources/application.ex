defmodule HousingApp.Management.Application do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource, AshAdmin.Api],
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      constraints min_length: 1, trim?: true
      allow_nil? false
    end

    attribute :description, :string do
      default ""
      allow_nil? false
    end

    attribute :status, :atom do
      constraints one_of: [:draft, :approved, :archived]
      default :draft
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
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

    belongs_to :form, HousingApp.Management.Form do
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
    table "applications"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :new do
      accept [:name, :description, :form_id]

      change set_attribute(:tenant_id, actor(:tenant_id))
    end

    read :list do
      prepare build(load: [:form])
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true

      prepare build(load: [:form])

      filter expr(id == ^arg(:id))
    end
  end

  code_interface do
    define_for HousingApp.Accounts

    define :list
    define :get_by_id, args: [:id]
  end

  multitenancy do
    strategy :context
  end
end
