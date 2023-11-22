defmodule HousingApp.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HousingApp.Tenants` context.
  """

  @doc """
  Generate a tenant.
  """
  def tenant_fixture(attrs \\ %{}) do
    {:ok, tenant} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> HousingApp.Accounts.create_tenant()

    tenant
  end

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "foo@bar.com",
        role: "user",
        password: "Password123!",
        password_confirmation: "Password123!"
      })
      |> HousingApp.Accounts.create_user()

    user
  end

  @doc """
  Generate a user_tenant.
  """
  def user_tenant_fixture(attrs \\ %{}) do
    {:ok, user_tenant} =
      attrs
      # |> Enum.into(%{
      #   tenant_id: Ecto.UUID.cast!("601d74e4-a8d3-4b6e-8365-eddb4c893327"),
      #   user_id: Ecto.UUID.cast!("801d74e4-a8d3-4b6e-8365-eddb4c893327")
      # })
      |> HousingApp.Accounts.create_user_tenant()

    user_tenant
  end
end
