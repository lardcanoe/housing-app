defmodule HousingApp.Accounts do
  @moduledoc """
  The Accounts context for Tenants and Users.
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
    registry HousingApp.Accounts.Registry
  end

  def create_tenant(attrs) do
    HousingApp.Accounts.Tenant
    |> Ash.Changeset.for_create(:create, attrs)
    |> HousingApp.Accounts.create()
  end

  def update_tenant(tenant, attrs) do
    tenant
    |> Ash.Changeset.for_update(:update, attrs)
    |> HousingApp.Accounts.update()
  end

  def delete_tenant(tenant) do
    tenant |> HousingApp.Accounts.destroy()
  end

  def list_tenants do
    HousingApp.Accounts.Tenant |> HousingApp.Accounts.read!()
  end

  ### ONLY USED FOR TENANT MIGRATIONS
  def all_tenants!() do
    %Ash.Query{resource: HousingApp.Accounts.Tenant} |> HousingApp.Accounts.read!()
  end

  def get_tenant!(id) do
    HousingApp.Accounts.Tenant
    |> Ash.Query.filter(id == ^id)
    |> HousingApp.Accounts.read_one!()
  end

  def create_user_tenant(attrs) do
    HousingApp.Accounts.UserTenant
    |> Ash.Changeset.for_create(:create, attrs)
    |> HousingApp.Accounts.create()
  end

  def update_user_tenant(user_tenant, attrs) do
    user_tenant
    |> Ash.Changeset.for_update(:update, attrs)
    |> HousingApp.Accounts.update()
  end

  def list_user_tenants() do
    HousingApp.Accounts.UserTenant |> HousingApp.Accounts.read!()
  end

  def get_user_tenant!(id) do
    HousingApp.Accounts.UserTenant
    |> Ash.Query.filter(id == ^id)
    |> HousingApp.Accounts.read_one!()
  end
end
