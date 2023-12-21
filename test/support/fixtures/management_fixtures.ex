defmodule HousingApp.ManagementFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HousingApp.Management` context.
  """

  def create_profile(attrs, tenant_id, opts \\ []) do
    attrs = Enum.into(attrs, %{"name" => "some name"})

    HousingApp.Management.Profile
    |> Ash.Changeset.for_create(:create, attrs, opts)
    |> Ash.Changeset.set_tenant("tenant_" <> tenant_id)
    |> HousingApp.Management.create()
  end
end
