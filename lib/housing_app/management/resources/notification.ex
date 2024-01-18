defmodule HousingApp.Management.Notification do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api],
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub]

  attributes do
    uuid_primary_key :id

    attribute :subject, :string do
      constraints min_length: 1, trim?: true
      allow_nil? false
    end

    attribute :message, :string do
      default ""
      allow_nil? false
    end

    attribute :read, :boolean do
      default false
      allow_nil? false
    end

    attribute :correlation, HousingApp.Management.Correlation

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

    belongs_to :user_tenant, HousingApp.Accounts.UserTenant do
      api HousingApp.Accounts
      attribute_writable? true
      allow_nil? false
    end
  end

  pub_sub do
    module Phoenix.PubSub
    name HousingApp.PubSub
    prefix "notification"
    broadcast_type :broadcast

    publish :create, [:user_tenant_id, "created"], event: "notification-created"
  end

  policies do
    bypass always() do
      authorize_if HousingApp.Checks.IsPlatformAdmin
    end

    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if HousingApp.Checks.IsTenantAdmin
      authorize_if relates_to_actor_via(:user_tenant)
    end

    policy action_type(:update) do
      authorize_if HousingApp.Checks.IsTenantAdmin
      authorize_if relates_to_actor_via(:user_tenant)
    end

    policy action(:count_unread) do
      authorize_if always()
    end
  end

  postgres do
    table "notifications"
    repo HousingApp.Repo

    custom_indexes do
      index [:user_tenant_id]
    end
  end

  actions do
    defaults [:create, :read, :update]

    read :list do
      prepare build(sort: [created_at: :desc])
      filter expr(user_tenant_id == ^actor(:id) and is_nil(archived_at))
    end

    read :list_unread do
      prepare build(sort: [created_at: :desc])
      filter expr(user_tenant_id == ^actor(:id) and not read and is_nil(archived_at))
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true

      filter expr(id == ^arg(:id) and is_nil(archived_at))
    end

    action :count_unread, :integer do
      run fn _, context ->
        __MODULE__
        |> Ash.Query.for_read(:list_unread, %{}, actor: context.actor, tenant: context.tenant)
        |> HousingApp.Management.count()
      end
    end

    update :mark_as_read do
      accept []
      change set_attribute(:read, true)
    end

    destroy :archive do
      primary? true
      soft? true
      change set_attribute(:archived_at, &DateTime.utc_now/0)
    end
  end

  code_interface do
    define_for HousingApp.Management

    define :list
    define :list_unread
    define :get_by_id, args: [:id]
    define :mark_as_read
    define :count_unread
  end

  multitenancy do
    strategy :context
  end
end
