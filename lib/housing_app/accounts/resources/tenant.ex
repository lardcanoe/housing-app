defmodule HousingApp.Accounts.Tenant do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, constraints: [trim?: true, min_length: 1, max_length: 128]

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :archived_at, :utc_datetime_usec do
      private? true
      allow_nil? true
    end
  end

  relationships do
    has_many :user_tenants, HousingApp.Accounts.UserTenant
  end

  postgres do
    table "tenants"
    repo HousingApp.Repo

    references do
      reference :user_tenants, on_delete: :delete
    end

    manage_tenant do
      template ["tenant_", :id]
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      get? true

      filter expr(id == ^arg(:id) and is_nil(archived_at))
    end

    read :list_unscoped do
    end
  end

  code_interface do
    define_for HousingApp.Accounts

    define :list_unscoped
    define :get_by_id, args: [:id]
  end
end
