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

  def register_user_with_password(params) do
    HousingApp.Accounts.User
    |> Ash.Changeset.for_create(:register_with_password, params)
    |> HousingApp.Accounts.create!()
  end

  def get_user!(id) do
    HousingApp.Accounts.User
    |> Ash.Query.filter(id == ^id)
    |> HousingApp.Accounts.read_one!()
  end

  def list_users do
    HousingApp.Accounts.User |> HousingApp.Accounts.read!()
  end

  def create_tenant(params) do
    HousingApp.Accounts.Tenant
    |> Ash.Changeset.for_create(:create, params)
    |> HousingApp.Accounts.create()
  end

  def update_tenant(tenant, params) do
    tenant
    |> Ash.Changeset.for_update(:update, params)
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

  # Actor should be a user_tenant
  def create_user_tenant(params, opts) do
    HousingApp.Accounts.UserTenant
    |> Ash.Changeset.for_create(:create, params, opts)
    |> Ash.Changeset.load([:user, :tenant])
    |> HousingApp.Accounts.create()
  end

  # Actor should be a user_tenant
  def update_user_tenant(user_tenant, params, opts) do
    user_tenant
    |> Ash.Changeset.for_update(:update, params, opts)
    |> HousingApp.Accounts.update()
  end

  def list_user_tenants!() do
    HousingApp.Accounts.UserTenant
    |> Ash.Query.for_read(:read, %{}, authorize?: false)
    |> HousingApp.Accounts.read!()
  end

  def list_user_tenants!(user_id, opts) do
    HousingApp.Accounts.UserTenant
    |> Ash.Query.for_read(:read, %{}, opts)
    |> Ash.Query.filter(user_id == ^user_id)
    |> Ash.Query.load(tenant: [:id, :name])
    |> HousingApp.Accounts.read!()
  end

  def get_user_tenant!(id, opts) do
    HousingApp.Accounts.UserTenant
    |> Ash.Query.for_read(:read, %{}, opts)
    |> Ash.Query.filter(id == ^id)
    |> Ash.Query.load([:user, :tenant])
    |> HousingApp.Accounts.read_one!()
  end

  def get_user_tenant!(user_id, tenant_id, opts) do
    HousingApp.Accounts.UserTenant
    |> Ash.Query.for_read(:read, %{}, opts)
    |> Ash.Query.filter(user_id == ^user_id and tenant_id == ^tenant_id)
    |> Ash.Query.load([:user, :tenant])
    |> HousingApp.Accounts.read_one!()
  end

  def get_default_user_tenant_for!(user_id, opts) do
    HousingApp.Accounts.UserTenant
    |> Ash.Query.for_read(:read, %{}, opts)
    |> Ash.Query.filter(user_id == ^user_id)
    |> Ash.Query.sort(created_at: :asc)
    |> Ash.Query.limit(1)
    |> Ash.Query.load([:user, :tenant])
    |> HousingApp.Accounts.read_one!()
  end
end