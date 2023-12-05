defmodule HousingApp.ManagementTest do
  @moduledoc false

  use HousingApp.DataCase

  alias HousingApp.Management

  describe "profiles" do
    import HousingApp.AccountsFixtures

    test "list_profiles/0 returns all profiles" do
      # Tenant 1
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{"tenant_id" => tenant.id, "user_id" => user.id, "user_type" => :admin}, actor: user)
      {:ok, _} = Management.create_profile(%{"user_tenant_id" => user_tenant.id}, tenant.id, actor: user_tenant)

      # Tenant 2
      tenant2 = tenant_fixture()
      user2 = user_fixture(%{"email" => "foo2@bar.com"})
      user_tenant2 = user_tenant_fixture(%{"tenant_id" => tenant2.id, "user_id" => user2.id, "user_type" => :admin}, actor: user2)
      {:ok, profile2} = Management.create_profile(%{"user_tenant_id" => user_tenant2.id}, tenant2.id, actor: user_tenant2)

      # Only get Profile for Tenant 2
      assert Management.list_profiles(tenant2.id, actor: user_tenant2) |> Enum.map(& &1.id) == [profile2.id]
    end

    test "Regular user can't create a profile" do
      tenant = tenant_fixture()
      user = user_fixture()
      user_tenant = user_tenant_fixture(%{"tenant_id" => tenant.id, "user_id" => user.id, "user_type" => :user}, actor: user)

      {:error, %Ash.Error.Forbidden{}} =
        Management.create_profile(%{"user_tenant_id" => user_tenant.id}, tenant.id, actor: user_tenant)
    end

    test "Regular user can't read another user's profile" do
      tenant = tenant_fixture()
      user1 = user_fixture()
      user_tenant1 = user_tenant_fixture(%{"tenant_id" => tenant.id, "user_id" => user1.id, "user_type" => :admin}, actor: user1)
      {:ok, user_profile1} = Management.create_profile(%{"user_tenant_id" => user_tenant1.id}, tenant.id, actor: user_tenant1)

      user2 = user_fixture(%{"email" => "foo2@bar.com"})
      user_tenant2 = user_tenant_fixture(%{"tenant_id" => tenant.id, "user_id" => user2.id, "user_type" => :user}, actor: user2)

      # User 2 can't read User 1's profile
      assert nil == Management.get_profile!(user_profile1.id, tenant.id, actor: user_tenant2)

      # User 1 can read self though
      read_profile = Management.get_profile!(user_profile1.id, tenant.id, actor: user_tenant1)
      assert read_profile.id == user_profile1.id
    end
  end
end
