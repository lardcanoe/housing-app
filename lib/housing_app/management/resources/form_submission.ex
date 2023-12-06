defmodule HousingApp.Management.FormSubmission do
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

    belongs_to :form, HousingApp.Management.Form do
      attribute_writable? true
      allow_nil? false
    end
  end

  # policies do
  #   bypass always() do
  #     authorize_if HousingApp.Checks.IsPlatformAdmin
  #     authorize_if HousingApp.Checks.IsTenantAdmin
  #   end

  #   policy action_type(:read) do
  #     authorize_if always()
  #   end
  # end

  postgres do
    table "form_submissions"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :submit do
      accept [:form_id, :data]

      change set_attribute(:tenant_id, actor(:tenant_id))
      change set_attribute(:user_tenant_id, actor(:id))
    end

    # read :list do
    #   prepare build(select: [:id, :name, :description, :status])
    # end

    # read :get_by_id do
    #   argument :id, :uuid do
    #     allow_nil? false
    #   end

    #   get? true

    #   filter expr(id == ^arg(:id))
    # end
  end

  code_interface do
    define_for HousingApp.Management

    define :submit
    # define :get_by_id, args: [:id]
  end

  multitenancy do
    strategy :context
  end
end
