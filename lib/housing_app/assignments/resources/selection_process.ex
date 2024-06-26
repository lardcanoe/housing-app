defmodule HousingApp.Assignments.SelectionProcess do
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

    attribute :process, :atom do
      constraints one_of: [:assignments_select_bed]
      allow_nil? false
    end

    attribute :criterion, {:array, HousingApp.Assignments.SelectionProcessCriteria} do
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
    table "selection_processes"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update]

    create :new do
      change set_attribute(:tenant_id, actor(:tenant_id))
    end

    create :copy do
      argument :source, :map do
        allow_nil? false
      end

      change fn changeset, context ->
        Ash.Changeset.change_attributes(
          changeset,
          HousingApp.Utils.Forms.copy_resource(__MODULE__, changeset.arguments.source)
        )
      end
    end

    read :list do
      prepare build(sort: [:name])
      filter expr(is_nil(archived_at))
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      prepare build(load: [criterion: [criteria: [conditions: :common_query, filters: :common_query]]])
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
    define :copy, args: [:source]
  end

  multitenancy do
    strategy :context
  end
end
