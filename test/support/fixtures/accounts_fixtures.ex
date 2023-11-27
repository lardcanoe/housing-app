defmodule HousingApp.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HousingApp.Accounts` context.
  """

  @doc """
  Generate a tenant.
  """
  def tenant_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "name" => "some name"
      })

    {:ok, tenant} = HousingApp.Accounts.create_tenant(attrs)
    tenant
  end

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "email" => "foo@bar.com",
        "password" => "Password123!",
        "password_confirmation" => "Password123!"
      })

    HousingApp.Accounts.User
    |> Ash.Changeset.for_create(:register_with_password, attrs)
    |> HousingApp.Accounts.create!()
  end

  @doc """
  Generate a user_tenant.
  """
  def user_tenant_fixture(attrs) do
    {:ok, ut} = HousingApp.Accounts.create_user_tenant(attrs)
    ut
  end
end
