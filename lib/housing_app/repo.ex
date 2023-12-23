defmodule HousingApp.Repo do
  use AshPostgres.Repo, otp_app: :housing_app

  def installed_extensions do
    ["uuid-ossp", "citext"]
  end

  def all_tenants do
    Enum.map(HousingApp.Accounts.Tenant.list_unscoped!(), fn t -> "tenant_#{t.id}" end)
  end
end
