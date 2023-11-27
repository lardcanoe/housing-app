defmodule HousingApp.Management do
  @moduledoc """
  The Management context for Profiles.
  """
  require Ash.Query

  use Ash.Api,
    otp_app: :housing_app,
    extensions: [AshAdmin.Api]

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

  def create_profile(attrs, tenant_id, opts \\ []) do
    HousingApp.Management.Profile
    |> Ash.Changeset.for_create(:create, attrs, opts)
    |> Ash.Changeset.set_tenant("tenant_" <> tenant_id)
    |> HousingApp.Management.create()
  end

  def list_profiles(tenant_id, opts \\ []) do
    HousingApp.Management.Profile
    |> Ash.Query.set_actor(opts)
    |> Ash.Query.set_tenant("tenant_" <> tenant_id)
    |> HousingApp.Management.read!()
  end
end
