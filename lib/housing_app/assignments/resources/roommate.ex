defmodule HousingApp.Assignments.Roommate do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api]

  # authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

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

    belongs_to :roommate_group, HousingApp.Assignments.RoommateGroup do
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :user_tenant, HousingApp.Accounts.UserTenant do
      api HousingApp.Accounts
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :roommate_invite, HousingApp.Assignments.RoommateInvite do
      attribute_writable? true
      allow_nil? true
    end
  end

  # policies do
  #   bypass always() do
  #     authorize_if HousingApp.Checks.IsPlatformAdmin
  #     authorize_if HousingApp.Checks.IsTenantAdmin
  #   end
  # end

  postgres do
    table "roommates"
    repo HousingApp.Repo

    custom_indexes do
      index [:user_tenant_id]
    end

    custom_indexes do
      index [:roommate_group_id]
    end
  end

  actions do
    defaults [:create, :read, :update]

    create :new do
      accept [:roommate_group_id, :roommate_invite_id]

      change set_attribute(:tenant_id, actor(:tenant_id))
      change set_attribute(:user_tenant_id, actor(:id))
    end

    read :list do
      prepare build(load: [:roommate_group, user_tenant: [:user]])
      filter expr(is_nil(archived_at))
    end

    read :list_mine do
      filter expr(user_tenant_id == ^actor(:id) and is_nil(archived_at))
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
    define :list
    define :list_mine
  end

  identities do
    identity :unique_by_group_and_user, [:roommate_group_id, :user_tenant_id]
  end

  multitenancy do
    strategy :context
  end
end
