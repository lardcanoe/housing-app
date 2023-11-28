defmodule HousingApp.Accounts.Tenant do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource]

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, constraints: [trim?: true, min_length: 1, max_length: 128]
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
  end
end
