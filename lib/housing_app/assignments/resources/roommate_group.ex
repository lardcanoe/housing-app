defmodule HousingApp.Assignments.RoommateGroup do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api]

  # authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      constraints min_length: 1, trim?: true
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

    belongs_to :created_by, HousingApp.Accounts.UserTenant do
      api HousingApp.Accounts
      attribute_writable? true
      allow_nil? false
    end

    has_many :members, HousingApp.Assignments.Roommate do
      source_attribute :id
      destination_attribute :roommate_group_id
    end

    has_many :invites, HousingApp.Assignments.RoommateInvite do
      source_attribute :id
      destination_attribute :roommate_group_id
    end
  end

  # policies do
  #   bypass always() do
  #     authorize_if HousingApp.Checks.IsPlatformAdmin
  #     authorize_if HousingApp.Checks.IsTenantAdmin
  #   end
  # end

  postgres do
    table "roommate_groups"
    repo HousingApp.Repo

    custom_indexes do
      index [:created_by_id]
    end
  end

  actions do
    defaults [:create, :read, :update]

    create :new do
      accept [:name]
      change set_attribute(:tenant_id, actor(:tenant_id))
      change set_attribute(:created_by_id, actor(:id))
    end

    # TODO: Only an owner or member should be able to read
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

    define :new
    define :get_by_id, args: [:id]
  end

  aggregates do
    count :count_of_accepted, :members do
      filter expr(status == :accepted and is_nil(archived_at))
    end

    count :count_of_pending, :members do
      filter expr(status == :pending and is_nil(archived_at))
    end
  end

  multitenancy do
    strategy :context
  end
end
