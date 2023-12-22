defmodule HousingApp.Management.ApplicationStepSubmission do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api]

  # authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :step_id, :uuid do
      allow_nil? false
    end

    attribute :data, :map do
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

    belongs_to :application_submission, HousingApp.Management.ApplicationSubmission do
      attribute_writable? true
      allow_nil? false
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
    table "application_step_submissions"
    repo HousingApp.Repo

    custom_indexes do
      index [:application_submission_id]
    end

    custom_indexes do
      index [:data], using: "GIN"
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :submit do
      accept [:application_submission_id, :step_id, :data]
      upsert? true
      change set_attribute(:tenant_id, actor(:tenant_id))
    end

    update :resubmit do
      accept [:data]
    end

    read :list_by_application_submission do
      argument :application_submission_id, :uuid do
        allow_nil? false
      end

      filter expr(application_submission == ^arg(:application_submission_id) and is_nil(archived_at))
    end

    read :get_by_step_id do
      argument :application_submission_id, :uuid do
        allow_nil? false
      end

      argument :step_id, :uuid do
        allow_nil? false
      end

      get? true

      filter expr(
               step_id == ^arg(:step_id) and application_submission_id == ^arg(:application_submission_id) and
                 is_nil(archived_at)
             )
    end
  end

  code_interface do
    define_for HousingApp.Management

    define :submit
    define :resubmit
    define :list_by_application_submission, args: [:application_submission_id]
    define :get_by_step_id, args: [:application_submission_id, :step_id]
  end

  identities do
    identity :unique_submission_step, [:application_submission_id, :step_id]
  end

  multitenancy do
    strategy :context
  end
end
