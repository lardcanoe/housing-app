defmodule HousingApp.Accounts.Faker do
  @moduledoc """
  Generates fake data for the application.
  """

  def generate(%{"students" => "0"}, _opts) do
    []
  end

  def generate(%{"students" => students}, [tenant: tenant, actor: actor] = _opts) do
    user_count = String.to_integer(students)

    {:ok, profile_form} = HousingApp.Management.Service.get_profile_form(actor: actor, tenant: tenant)
    json_schema = Jason.decode!(profile_form.json_schema)

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
      |> Ash.Changeset.for_create(
        :create,
        %{user_tenant_id: ut.id, tenant_id: actor.tenant_id, data: generate_profile_data(json_schema["properties"])},
        actor: actor,
        tenant: tenant
      )
      |> HousingApp.Management.create()
    end)
  end

  def generate_profile_data(properties) do
    Map.new(properties, fn {key, field} ->
      case key do
        "name" -> {"name", Faker.Person.name()}
        "city" -> {"city", Faker.Address.city()}
        "state" -> {"state", Faker.Address.state_abbr()}
        _ -> {key, generate_field_data(field)}
      end
    end)
  end

  def generate_field_data(%{"enum" => enum}), do: Enum.random(enum)
  def generate_field_data(%{"type" => "string", "format" => "email"}), do: Faker.Internet.email()
  def generate_field_data(%{"type" => "string", "format" => "color"}), do: "#" <> Faker.Color.rgb_hex()
  def generate_field_data(%{"type" => "string", "format" => "date"}), do: Faker.Date.date_of_birth()
  def generate_field_data(%{"type" => "string"}), do: Faker.Lorem.sentence(1..4)

  def generate_field_data(%{"type" => "integer"} = field) do
    Faker.random_between(field["minimum"] || 0, field["maximum"] || 100)
  end

  def generate_field_data(%{"type" => "boolean"}), do: Faker.random_between(0, 1)
  def generate_field_data(%{"type" => "object", "properties" => properties}), do: generate_profile_data(properties)
  def generate_field_data(_), do: ""
end
