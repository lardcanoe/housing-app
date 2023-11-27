defmodule HousingApp.Accounts.Tenant do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tenants"
    repo HousingApp.Repo

    references do
      reference :user_tenants, on_delete: :delete
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
  end

  relationships do
    has_many :user_tenants, HousingApp.Accounts.UserTenant
  end
end
