defmodule HousingApp.Accounts.Faker do
  @moduledoc """
  Generates fake data for the application.
  """

  def generate(%{"students" => "0"}, _opts) do
    []
  end

  def generate(%{"students" => students}, [tenant: tenant, actor: actor] = _opts) do
    user_count = String.to_integer(students)

    user_count
    |> Faker.Util.sample_uniq(&Faker.Internet.email/0)
    |> Enum.map(fn email ->
      {:ok, user} =
        HousingApp.Accounts.User
        |> Ash.Changeset.for_create(
          :register_with_password,
          %{
            "name" => Faker.Person.name(),
            "email" => email,
            "password" => "Password123!",
            "password_confirmation" => "Password123!"
          },
          actor: actor
        )
        |> HousingApp.Accounts.create()

      {:ok, ut} =
        HousingApp.Accounts.UserTenant
        |> Ash.Changeset.for_create(:create, %{user_id: user.id, tenant_id: actor.tenant_id, user_type: :user},
          tenant: tenant,
          actor: actor
        )
        |> HousingApp.Accounts.create()

      HousingApp.Management.Profile
      |> Ash.Changeset.for_create(:create, %{user_tenant_id: ut.id, tenant_id: actor.tenant_id},
        actor: actor,
        tenant: tenant
      )
      |> HousingApp.Management.create()
    end)
  end
end
