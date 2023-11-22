defmodule HousingApp.AccountsTest do
  @moduledoc false

  use HousingApp.DataCase

  alias HousingApp.Accounts

  describe "tenants" do
    alias HousingApp.Accounts.Tenant

    import HousingApp.AccountsFixtures

    @invalid_attrs %{name: nil}

    test "list_tenants/0 returns all tenants" do
      tenant = tenant_fixture()
      assert Accounts.list_tenants() == [tenant]
    end

    test "get_tenant!/1 returns the tenant with given id" do
      tenant = tenant_fixture()
      assert Accounts.get_tenant!(tenant.id) == tenant
    end

    test "create_tenant/1 with valid data creates a tenant" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Tenant{} = tenant} = Accounts.create_tenant(valid_attrs)
      assert tenant.name == "some name"
    end

    test "create_tenant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_tenant(@invalid_attrs)
    end

    test "update_tenant/2 with valid data updates the tenant" do
      tenant = tenant_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Tenant{} = tenant} = Accounts.update_tenant(tenant, update_attrs)
      assert tenant.name == "some updated name"
    end

    test "update_tenant/2 with invalid data returns error changeset" do
      tenant = tenant_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_tenant(tenant, @invalid_attrs)
      assert tenant == Accounts.get_tenant!(tenant.id)
    end

    test "delete_tenant/1 deletes the tenant" do
      tenant = tenant_fixture()
      assert {:ok, %Tenant{}} = Accounts.delete_tenant(tenant)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_tenant!(tenant.id) end
    end

    test "change_tenant/1 returns a tenant changeset" do
      tenant = tenant_fixture()
      assert %Ecto.Changeset{} = Accounts.change_tenant(tenant)
    end
  end

  describe "user_tenants" do
    alias HousingApp.Accounts.UserTenant

    import HousingApp.AccountsFixtures

    @invalid_user_tenant_attrs %{user_id: nil, tenant_id: nil, role: "foo"}

    test "list_user_tenants/0 returns all user_tenants" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{tenant_id: tenant.id, user_id: user.id})
      assert Accounts.list_user_tenants() == [user_tenant]
    end

    test "get_user_tenant!/1 returns the user_tenant with given id" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{tenant_id: tenant.id, user_id: user.id})
      assert Accounts.get_user_tenant!(user_tenant.id) == user_tenant
    end

    test "create_user_tenant/1 with valid data creates a user_tenant" do
      tenant = tenant_fixture()
      user = user_fixture()

      assert {:ok, %UserTenant{} = user_tenant} =
               Accounts.create_user_tenant(%{tenant_id: tenant.id, user_id: user.id})

      assert user_tenant.user_id == user.id
      assert user_tenant.tenant_id == tenant.id
    end

    test "create_user_tenant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user_tenant(@invalid_user_tenant_attrs)
    end

    # test "update_user_tenant/2 with valid data updates the user_tenant" do
    #   user_tenant = user_tenant_fixture()

    #   update_attrs = %{
    #     user_id: Ecto.UUID.cast!("801d74e4-a8d3-4b6e-8365-eddb4c893322"),
    #     tenant_id: Ecto.UUID.cast!("601d74e4-a8d3-4b6e-8365-eddb4c893322")
    #   }

    #   assert {:ok, %UserTenant{} = user_tenant} =
    #            Accounts.update_user_tenant(user_tenant, update_attrs)

    #   assert user_tenant.user_id == Ecto.UUID.cast!("801d74e4-a8d3-4b6e-8365-eddb4c893322")
    #   assert user_tenant.tenant_id == Ecto.UUID.cast!("601d74e4-a8d3-4b6e-8365-eddb4c893322")
    # end

    test "update_user_tenant/2 with invalid data returns error changeset" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{tenant_id: tenant.id, user_id: user.id})

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_user_tenant(user_tenant, @invalid_user_tenant_attrs)

      assert user_tenant == Accounts.get_user_tenant!(user_tenant.id)
    end

    test "delete_user_tenant/1 deletes the user_tenant" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{tenant_id: tenant.id, user_id: user.id})
      assert {:ok, %UserTenant{}} = Accounts.delete_user_tenant(user_tenant)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user_tenant!(user_tenant.id) end
    end

    test "change_user_tenant/1 returns a user_tenant changeset" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{tenant_id: tenant.id, user_id: user.id})
      assert %Ecto.Changeset{} = Accounts.change_user_tenant(user_tenant)
    end
  end
end
