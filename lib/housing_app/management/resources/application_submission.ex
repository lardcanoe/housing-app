defmodule HousingApp.Management.ApplicationSubmission do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api]

  # authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :data, :map do
      allow_nil? false
    end

    attribute :status, :atom do
      constraints one_of: [:started, :completed, :rejected]
      default :started
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

    belongs_to :user_tenant, HousingApp.Accounts.UserTenant do
      api HousingApp.Accounts
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :application, HousingApp.Management.Application do
      attribute_writable? true
      allow_nil? false
    end

    has_many :step_submissions, HousingApp.Management.ApplicationStepSubmission do
      source_attribute :id
      destination_attribute :application_submission_id
    end
  end

  # policies do
  #   bypass always() do
  #     authorize_if HousingApp.Checks.IsPlatapplicationAdmin
  #     authorize_if HousingApp.Checks.IsTenantAdmin
  #   end

  #   policy action_type(:read) do
  #     authorize_if always()
  #   end
  # end

  postgres do
    table "application_submissions"
    repo HousingApp.Repo

    custom_indexes do
      index [:user_tenant_id]
    end

    custom_indexes do
      index [:application_id]
    end

    custom_indexes do
      index [:data], using: "GIN"
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :start do
      accept [:application_id]

      change set_attribute(:data, %{})
      change set_attribute(:tenant_id, actor(:tenant_id))
      change set_attribute(:user_tenant_id, actor(:id))
    end

    create :submit do
      accept [:application_id, :data, :status]

      change set_attribute(:tenant_id, actor(:tenant_id))
      change set_attribute(:user_tenant_id, actor(:id))
    end

    update :resubmit do
      accept [:data, :status]
    end

    read :list_by_application do
      argument :application_id, :uuid do
        allow_nil? false
      end

      prepare build(load: [user_tenant: [:user]])

      filter expr(application_id == ^arg(:application_id) and is_nil(archived_at))
    end

    read :list_by_user_tenant do
      argument :user_tenant_id, :uuid do
        allow_nil? false
      end

      filter expr(user_tenant_id == ^arg(:user_tenant_id) and is_nil(archived_at))
    end

    read :get_submission do
      argument :application_id, :uuid do
        allow_nil? false
      end

      argument :user_tenant_id, :uuid do
        allow_nil? false
      end

      get? true

      filter expr(
               user_tenant_id == ^arg(:user_tenant_id) and application_id == ^arg(:application_id) and
                 is_nil(archived_at)
             )
    end
  end

  code_interface do
    define_for HousingApp.Management

    define :start
    define :submit
    define :resubmit
    define :list_by_application, args: [:application_id]
    define :list_by_user_tenant, args: [:user_tenant_id]
    define :get_submission, args: [:application_id, :user_tenant_id]
  end

  multitenancy do
    strategy :context
  end
end
