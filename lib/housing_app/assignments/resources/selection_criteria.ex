defmodule HousingApp.Assignments.SelectionCriteria do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      constraints min_length: 1, trim?: true
      allow_nil? false
    end

    attribute :description, :string do
      default ""
    end

    attribute :conditions, {:array, HousingApp.Assignments.SelectionCondition} do
      default []
      allow_nil? false
    end

    attribute :filters, {:array, HousingApp.Assignments.SelectionFilter} do
      default []
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :archived_at, :utc_datetime_usec do
      private? true
      allow_nil? true
    end
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

    policy action_type(:read) do
      authorize_if always()
    end
  end

  postgres do
    table "selection_criteria"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update]

    create :new do
      change set_attribute(:tenant_id, actor(:tenant_id))
    end

    read :list do
      prepare build(sort: [:name])
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
    define_for HousingApp.Assignments

    define :list
    define :get_by_id, args: [:id]
  end

  multitenancy do
    strategy :context
  end
end
