defmodule HousingApp.Accounts.Registry do
  use Ash.Registry

  entries do
    entry HousingApp.Accounts.Token
    entry HousingApp.Accounts.User
    entry HousingApp.Accounts.Tenant
    entry HousingApp.Accounts.UserTenant
  end
end
