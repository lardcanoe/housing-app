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

    @invalid_user_tenant_attrs %{"user_id" => nil, "tenant_id" => nil, "user_type" => "foo"}

    test "list_user_tenants!/0 returns all user_tenants" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{"tenant_id" => tenant.id, "user_id" => user.id}, actor: user)
      assert Accounts.list_user_tenants!() |> Enum.map(& &1.id) == [user_tenant.id]
    end

    test "UserTenant.get_by_id!/1 returns the user_tenant with given id" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{tenant_id: tenant.id, user_id: user.id}, actor: user)
      fetched = Accounts.UserTenant.get_by_id!(user_tenant.id, actor: user)
      assert fetched.id == user_tenant.id
      assert fetched.user_id == user.id
      assert fetched.tenant_id == tenant.id
    end

    test "UserTenant.get_by_id!/1 fails for different user" do
      tenant = tenant_fixture()
      user = user_fixture()
      user2 = user_fixture(%{"email" => "foo2@bar.com"})
      user_tenant = user_tenant_fixture(%{tenant_id: tenant.id, user_id: user.id}, actor: user)

      assert_raise Ash.Error.Query.NotFound, fn ->
        Accounts.UserTenant.get_by_id!(user_tenant.id, actor: user2)
      end
    end

    test "create_user_tenant/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} =
               Accounts.create_user_tenant(@invalid_user_tenant_attrs, actor: nil)
    end

    test "change_user_tenant/1 user cannot promote self to admin" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{"tenant_id" => tenant.id, "user_id" => user.id, "user_type" => :user}, actor: user)
      assert user_tenant.user_type == :user
      {:error, %Ash.Error.Forbidden{}} = Accounts.update_user_tenant(user_tenant, %{"user_type" => :admin}, actor: user_tenant)
      assert Accounts.UserTenant.get_by_id!(user_tenant.id, actor: user).user_type == :user
    end

    test "change_user_tenant/1 staff cannot promote self to admin" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{"tenant_id" => tenant.id, "user_id" => user.id, "user_type" => :staff}, actor: user)
      assert user_tenant.user_type == :staff
      {:error, %Ash.Error.Forbidden{}} = Accounts.update_user_tenant(user_tenant, %{"user_type" => :admin}, actor: user_tenant)
      assert Accounts.UserTenant.get_by_id!(user_tenant.id, actor: user).user_type == :staff
    end

    test "change_user_tenant/1 admin downgrade to staff" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{"tenant_id" => tenant.id, "user_id" => user.id, "user_type" => :admin}, actor: user)
      assert user_tenant.user_type == :admin
      {:ok, _} = Accounts.update_user_tenant(user_tenant, %{"user_type" => :staff}, actor: user_tenant)
      assert Accounts.UserTenant.get_by_id!(user_tenant.id, actor: user).user_type == :staff
    end
  end
end
