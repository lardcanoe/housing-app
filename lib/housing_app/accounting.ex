defmodule HousingApp.Accounting do
  @moduledoc """
  The Accounting context.
  """
  use Ash.Api, otp_app: :housing_app, extensions: [AshAdmin.Api]

  require Ash.Query

  # https://hexdocs.pm/ash/dsl-ash-api.html#authorization
  # https://hexdocs.pm/ash/security.html#authorization-configuration
  authorization do
    authorize :by_default
  end

  admin do
    show?(true)
  end

  resources do
    registry HousingApp.Accounting.Registry
  end
end
