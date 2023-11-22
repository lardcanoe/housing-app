defmodule HousingApp.Accounts do
  @moduledoc """
  The Accounts context for Tenants and Users.
  """

  import Ecto.Query, warn: false
  alias HousingApp.Repo

  alias HousingApp.Accounts.Tenant

  @doc """
  Returns the list of tenants.

  ## Examples

      iex> list_tenants()
      [%Tenant{}, ...]

  """
  def list_tenants do
    Repo.all(Tenant)
  end

  @doc """
  Gets a single tenant.

  Raises `Ecto.NoResultsError` if the Tenant does not exist.

  ## Examples

      iex> get_tenant!(123)
      %Tenant{}

      iex> get_tenant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tenant!(id), do: Repo.get!(Tenant, id)

  @doc """
  Creates a tenant.

  ## Examples

      iex> create_tenant(%{field: value})
      {:ok, %Tenant{}}

      iex> create_tenant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tenant(attrs \\ %{}) do
    %Tenant{}
    |> Tenant.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tenant.

  ## Examples

      iex> update_tenant(tenant, %{field: new_value})
      {:ok, %Tenant{}}

      iex> update_tenant(tenant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tenant(%Tenant{} = tenant, attrs) do
    tenant
    |> Tenant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tenant.

  ## Examples

      iex> delete_tenant(tenant)
      {:ok, %Tenant{}}

      iex> delete_tenant(tenant)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tenant(%Tenant{} = tenant) do
    Repo.delete(tenant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tenant changes.

  ## Examples

      iex> change_tenant(tenant)
      %Ecto.Changeset{data: %Tenant{}}

  """
  def change_tenant(%Tenant{} = tenant, attrs \\ %{}) do
    Tenant.changeset(tenant, attrs)
  end

  alias HousingApp.Accounts.User

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  alias HousingApp.Accounts.UserTenant

  @doc """
  Returns the list of user_tenants.

  ## Examples

      iex> list_user_tenants()
      [%UserTenant{}, ...]

  """
  def list_user_tenants do
    Repo.all(UserTenant)
  end

  @doc """
  Gets a single user_tenant.

  Raises `Ecto.NoResultsError` if the User tenant does not exist.

  ## Examples

      iex> get_user_tenant!(123)
      %UserTenant{}

      iex> get_user_tenant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_tenant!(id), do: Repo.get!(UserTenant, id)

  @doc """
  Creates a user_tenant.

  ## Examples

      iex> create_user_tenant(%{field: value})
      {:ok, %UserTenant{}}

      iex> create_user_tenant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_tenant(attrs \\ %{}) do
    %UserTenant{}
    |> UserTenant.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_tenant.

  ## Examples

      iex> update_user_tenant(user_tenant, %{field: new_value})
      {:ok, %UserTenant{}}

      iex> update_user_tenant(user_tenant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_tenant(%UserTenant{} = user_tenant, attrs) do
    user_tenant
    |> UserTenant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_tenant.

  ## Examples

      iex> delete_user_tenant(user_tenant)
      {:ok, %UserTenant{}}

      iex> delete_user_tenant(user_tenant)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_tenant(%UserTenant{} = user_tenant) do
    Repo.delete(user_tenant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_tenant changes.

  ## Examples

      iex> change_user_tenant(user_tenant)
      %Ecto.Changeset{data: %UserTenant{}}

  """
  def change_user_tenant(%UserTenant{} = user_tenant, attrs \\ %{}) do
    UserTenant.changeset(user_tenant, attrs)
  end
end
