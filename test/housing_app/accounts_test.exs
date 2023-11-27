defmodule HousingApp.AccountsTest do
  @moduledoc false

  use HousingApp.DataCase

  alias HousingApp.Accounts

  describe "tenants" do
    alias HousingApp.Accounts.Tenant

    import HousingApp.AccountsFixtures

    @invalid_attrs %{"name" => nil}

    test "list_tenants/0 returns all tenants" do
      tenant = tenant_fixture()
      assert Accounts.list_tenants() |> Enum.map(& &1.id) == [tenant.id]
    end

    test "get_tenant!/1 returns the tenant with given id" do
      tenant = tenant_fixture()
      assert Accounts.get_tenant!(tenant.id).id == tenant.id
    end

    test "create_tenant/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = Accounts.create_tenant(%{"name" => ""})
    end

    test "update_tenant/2 with valid data updates the tenant" do
      tenant = tenant_fixture()
      update_attrs = %{"name" => "some updated name"}

      assert {:ok, %Tenant{} = updated_tenant} = Accounts.update_tenant(tenant, update_attrs)
      assert updated_tenant.name == "some updated name"
    end

    test "update_tenant/2 with invalid data returns error changeset" do
      tenant = tenant_fixture()
      assert {:error, %Ash.Error.Invalid{}} = Accounts.update_tenant(tenant, @invalid_attrs)
      assert tenant.name == Accounts.get_tenant!(tenant.id).name
    end

    test "delete_tenant/1 deletes the tenant" do
      tenant = tenant_fixture()
      assert :ok = Accounts.delete_tenant(tenant)
      assert nil == Accounts.get_tenant!(tenant.id)
    end
  end

  describe "user_tenants" do
    import HousingApp.AccountsFixtures

    @invalid_user_tenant_attrs %{"user_id" => nil, "tenant_id" => nil, "role" => "foo"}

    test "list_user_tenants/0 returns all user_tenants" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{"tenant_id" => tenant.id, "user_id" => user.id})
      assert Accounts.list_user_tenants() |> Enum.map(& &1.id) == [user_tenant.id]
    end

    test "get_user_tenant!/1 returns the user_tenant with given id" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{tenant_id: tenant.id, user_id: user.id})
      fetched = Accounts.get_user_tenant!(user_tenant.id)
      assert fetched.id == user_tenant.id
      assert fetched.user_id == user.id
      assert fetched.tenant_id == tenant.id
    end

    test "create_user_tenant/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} =
               Accounts.create_user_tenant(@invalid_user_tenant_attrs)
    end

    test "change_user_tenant/1 returns a user_tenant changeset" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{"tenant_id" => tenant.id, "user_id" => user.id})
      assert user_tenant.role == :user
      Accounts.update_user_tenant(user_tenant, %{"role" => :admin})
      assert Accounts.get_user_tenant!(user_tenant.id).role == :admin
    end
  end
end
