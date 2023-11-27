defmodule HousingApp.Accounts do
  @moduledoc """
  The Accounts context for Tenants and Users.
  """

  use Ash.Api,
    otp_app: :housing_app,
    extensions: [AshAdmin.Api]

  authorization do
    authorize :by_default
  end

  admin do
    show?(true)
  end

  resources do
    resource HousingApp.Accounts.Token
    resource HousingApp.Accounts.User
    resource HousingApp.Accounts.Tenant
    resource HousingApp.Accounts.UserTenant
  end
end
