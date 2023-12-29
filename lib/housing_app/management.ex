defmodule HousingApp.Management do
  @moduledoc """
  The Management context for Profiles.
  """
  use Ash.Api, otp_app: :housing_app, extensions: [AshAdmin.Api, AshJsonApi.Api]

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
    registry HousingApp.Management.Registry
  end
end
