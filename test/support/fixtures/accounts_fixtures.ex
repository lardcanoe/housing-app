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

    {:ok, tenant} =
      HousingApp.Accounts.Tenant
      |> Ash.Changeset.for_create(:create, attrs)
      |> HousingApp.Accounts.create()

    tenant
  end

  def tenant_direct(attrs) do
    HousingApp.Accounts.Tenant
    |> Ash.Changeset.for_create(:create, attrs)
    |> HousingApp.Accounts.create()
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
  def user_tenant_fixture!(params, opts) do
    {:ok, ut} =
      HousingApp.Accounts.UserTenant
      |> Ash.Changeset.for_create(:create, params, opts)
      |> Ash.Changeset.load([:user, :tenant])
      |> HousingApp.Accounts.create()

    ut
  end

  def user_tenant_fixture(params, opts) do
    HousingApp.Accounts.UserTenant
    |> Ash.Changeset.for_create(:create, params, opts)
    |> Ash.Changeset.load([:user, :tenant])
    |> HousingApp.Accounts.create()
  end
end
