defmodule HousingApp.Repo do
  use AshPostgres.Repo, otp_app: :housing_app

  def installed_extensions() do
    ["uuid-ossp", "citext"]
  end

  def all_tenants do
    for t <- HousingApp.Accounts.all_tenants!() do
      # This is broken sadly:
      # t.schema
      "tenant_#{t.id}"
    end
  end
end
