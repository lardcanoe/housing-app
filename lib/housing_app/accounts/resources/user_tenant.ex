defmodule HousingApp.Accounts.UserTenant do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "user_tenants"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :role, :atom do
      constraints one_of: [:user, :admin]
      default :user
      allow_nil? false
    end
  end

  relationships do
    belongs_to :user, HousingApp.Accounts.User do
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :tenant, HousingApp.Accounts.Tenant do
      attribute_writable? true
      allow_nil? false
    end
  end
end
