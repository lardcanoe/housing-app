defmodule HousingApp.AccountsTest do
  @moduledoc false

  use HousingApp.DataCase

  describe "tenants" do
    alias HousingApp.Accounts.Tenant

    import HousingApp.AccountsFixtures

    @invalid_attrs %{"name" => nil}

    test "list_tenants/0 returns all tenants" do
      tenant = tenant_fixture()
      assert HousingApp.Accounts.Tenant.list_unscoped!() |> Enum.map(& &1.id) == [tenant.id]
    end

    test "get_tenant!/1 returns the tenant with given id" do
      tenant = tenant_fixture()
      assert HousingApp.Accounts.Tenant.get_by_id!(tenant.id).id == tenant.id
    end

    test "create_tenant/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = tenant_direct(%{"name" => ""})
    end

    test "update_tenant/2 with valid data updates the tenant" do
      tenant = tenant_fixture()
      update_attrs = %{"name" => "some updated name"}

      assert {:ok, %Tenant{} = updated_tenant} =
               Ash.Changeset.for_update(tenant, :update, update_attrs) |> HousingApp.Accounts.update()

      assert updated_tenant.name == "some updated name"
    end

    test "update_tenant/2 with invalid data returns error changeset" do
      tenant = tenant_fixture()

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.Changeset.for_update(tenant, :update, @invalid_attrs) |> HousingApp.Accounts.update()

      assert tenant.name == HousingApp.Accounts.Tenant.get_by_id!(tenant.id).name
    end

    test "delete_tenant/1 deletes the tenant" do
      tenant = tenant_fixture()
      assert :ok = HousingApp.Accounts.destroy(tenant)
      assert_raise Ash.Error.Query.NotFound, fn -> HousingApp.Accounts.Tenant.get_by_id!(tenant.id) end
    end
  end

  describe "user_tenants" do
    import HousingApp.AccountsFixtures

    @invalid_user_tenant_attrs %{"user_id" => nil, "tenant_id" => nil, "user_type" => "foo"}

    test "list_user_tenants!/0 returns all user_tenants" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture!(%{"tenant_id" => tenant.id, "user_id" => user.id}, actor: user)

      uts =
        HousingApp.Accounts.UserTenant
        |> Ash.Query.for_read(:read, %{}, authorize?: false)
        |> HousingApp.Accounts.read!()
        |> Enum.map(& &1.id)

      assert uts == [user_tenant.id]
    end

    test "UserTenant.get_by_id!/1 returns the user_tenant with given id" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture!(%{tenant_id: tenant.id, user_id: user.id}, actor: user)
      fetched = HousingApp.Accounts.UserTenant.get_by_id!(user_tenant.id, actor: user)
      assert fetched.id == user_tenant.id
      assert fetched.user_id == user.id
      assert fetched.tenant_id == tenant.id
    end

    test "UserTenant.get_by_id!/1 fails for different user" do
      tenant = tenant_fixture()
      user = user_fixture()
      user2 = user_fixture(%{"email" => "foo2@bar.com"})
      user_tenant = user_tenant_fixture!(%{tenant_id: tenant.id, user_id: user.id}, actor: user)

      assert_raise Ash.Error.Query.NotFound, fn ->
        HousingApp.Accounts.UserTenant.get_by_id!(user_tenant.id, actor: user2)
      end
    end

    test "create_user_tenant/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = user_tenant_fixture(@invalid_user_tenant_attrs, actor: nil)
    end

    test "change_user_tenant/1 user cannot promote self to admin" do
      tenant = tenant_fixture()
      user = user_fixture()

      user_tenant =
        user_tenant_fixture!(%{"tenant_id" => tenant.id, "user_id" => user.id, "user_type" => :user}, actor: user)

      assert user_tenant.user_type == :user

      {:error, %Ash.Error.Forbidden{}} =
        Ash.Changeset.for_update(user_tenant, :update, %{"user_type" => :admin}, actor: user_tenant)
        |> HousingApp.Accounts.update()

      assert HousingApp.Accounts.UserTenant.get_by_id!(user_tenant.id, actor: user).user_type == :user
    end

    test "change_user_tenant/1 staff cannot promote self to admin" do
      tenant = tenant_fixture()
      user = user_fixture()

      user_tenant =
        user_tenant_fixture!(%{"tenant_id" => tenant.id, "user_id" => user.id, "user_type" => :staff}, actor: user)

      assert user_tenant.user_type == :staff

      {:error, %Ash.Error.Forbidden{}} =
        Ash.Changeset.for_update(user_tenant, :update, %{"user_type" => :admin}, actor: user_tenant)
        |> HousingApp.Accounts.update()

      assert HousingApp.Accounts.UserTenant.get_by_id!(user_tenant.id, actor: user).user_type == :staff
    end

    test "change_user_tenant/1 admin downgrade to staff" do
      tenant = tenant_fixture()
      user = user_fixture()

      user_tenant =
        user_tenant_fixture!(%{"tenant_id" => tenant.id, "user_id" => user.id, "user_type" => :admin}, actor: user)

      assert user_tenant.user_type == :admin

      {:ok, _} =
        Ash.Changeset.for_update(user_tenant, :update, %{"user_type" => :staff}, actor: user_tenant)
        |> HousingApp.Accounts.update()

      assert HousingApp.Accounts.UserTenant.get_by_id!(user_tenant.id, actor: user).user_type == :staff
    end
  end
end
