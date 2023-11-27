defmodule HousingApp.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HousingApp.Accounts` context.
  """

  @doc """
  Generate a tenant.
  """
  def tenant_fixture(attrs \\ %{}) do
    HousingApp.Accounts.Tenant
    |> Ash.Changeset.for_create(:create, %{name: "some name"})
    |> HousingApp.Accounts.create!()
  end

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    HousingApp.Accounts.User
    |> Ash.Changeset.for_create(:register_with_password, %{
      email: "foo@bar.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    })
    |> HousingApp.Accounts.create!()
  end

  @doc """
  Generate a user_tenant.
  """
  def user_tenant_fixture(attrs \\ %{}) do
    HousingApp.Accounts.UserTenant
    |> Ash.Changeset.for_create(:create, %{
      tenant_id: Ecto.UUID.cast!("601d74e4-a8d3-4b6e-8365-eddb4c893327"),
      user_id: Ecto.UUID.cast!("801d74e4-a8d3-4b6e-8365-eddb4c893327")
    })
    |> HousingApp.Accounts.create!()
  end
end
