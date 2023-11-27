defmodule HousingApp.Management do
  @moduledoc """
  The Management context for Profiles.
  """
  require Ash.Query

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
    registry HousingApp.Management.Registry
  end

  def create_profile(attrs, tenant_id) do
    HousingApp.Management.Profile
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.Changeset.set_tenant("tenant_" <> tenant_id)
    |> HousingApp.Management.create()
  end

  def list_profiles(tenant_id) do
    HousingApp.Management.Profile
    |> Ash.Query.set_tenant("tenant_" <> tenant_id)
    |> HousingApp.Management.read!()
  end
end
