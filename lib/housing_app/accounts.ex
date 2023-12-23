defmodule HousingApp.Accounts do
  @moduledoc """
  The Accounts context for Tenants and Users.
  """
  use Ash.Api, otp_app: :housing_app, extensions: [AshAdmin.Api]

  require Ash.Query

  authorization do
    authorize :by_default
  end

  admin do
    show?(true)
  end

  resources do
    registry HousingApp.Accounts.Registry
  end
end
