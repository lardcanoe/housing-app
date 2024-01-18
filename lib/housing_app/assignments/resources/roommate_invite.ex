defmodule HousingApp.Assignments.RoommateInvite do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api]

  # authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :status, :atom do
      constraints one_of: [:pending, :accepted, :declined]
      default :pending
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

    belongs_to :roommate_group, HousingApp.Assignments.RoommateGroup do
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :user_tenant, HousingApp.Accounts.UserTenant do
      api HousingApp.Accounts
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :invited_by, HousingApp.Accounts.UserTenant do
      api HousingApp.Accounts
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
    table "roommate_invites"
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

    create :invite do
      accept [:roommate_group_id, :user_tenant_id]
      change set_attribute(:status, :pending)
      change set_attribute(:tenant_id, actor(:tenant_id))
      change set_attribute(:invited_by_id, actor(:id))
    end

    update :accept do
      change set_attribute(:status, :accepted)
    end

    update :decline do
      change set_attribute(:status, :declined)
    end

    read :list_mine do
      filter expr(user_tenant_id == ^actor(:id) and status == :pending and is_nil(archived_at))
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true

      filter expr(id == ^arg(:id) and user_tenant_id == ^actor(:id) and is_nil(archived_at))
    end

    destroy :archive do
      primary? true
      soft? true
      change set_attribute(:archived_at, &DateTime.utc_now/0)
    end
  end

  code_interface do
    define_for HousingApp.Assignments
    define :invite
    define :accept
    define :decline
    define :list_mine
    define :get_by_id, args: [:id]
  end

  identities do
    identity :unique_by_group_and_user, [:roommate_group_id, :user_tenant_id]
  end

  multitenancy do
    strategy :context
  end
end
