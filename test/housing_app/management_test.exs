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
      user_tenant = user_tenant_fixture(%{"tenant_id" => tenant.id, "user_id" => user.id})
      HousingApp.Management.create_profile(%{"user_tenant_id" => user_tenant.id}, tenant.id)

      # Tenant 2
      tenant2 = tenant_fixture()
      user2 = user_fixture(%{"email" => "foo2@bar.com"})
      user_tenant2 = user_tenant_fixture(%{"tenant_id" => tenant2.id, "user_id" => user2.id})

      {:ok, profile2} =
        HousingApp.Management.create_profile(%{"user_tenant_id" => user_tenant2.id}, tenant2.id)

      # Only get Profile for Tenant 2
      assert Management.list_profiles(tenant2.id) |> Enum.map(& &1.id) == [profile2.id]
    end
  end
end
