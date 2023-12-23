defmodule HousingApp.Assignments.Faker do
  @moduledoc """
  Generates fake data for Assignments.
  """

  def generate(%{"buildings" => buildings, "rooms" => rooms}, [tenant: tenant, actor: actor] = _opts) do
    buildings = String.to_integer(buildings)
    rooms = String.to_integer(rooms)

    if buildings > 0 do
      rooms_per = trunc(:math.ceil(rooms / buildings))
      floors = trunc(:math.ceil(rooms_per / 30))
      rooms_per_floor = 30

      products = HousingApp.Accounting.Product.list!(tenant: tenant, actor: actor)

      buildings
      |> Faker.Util.sample_uniq(&Faker.Person.En.last_name/0)
      |> Enum.map(fn name ->
        {:ok, building} =
          HousingApp.Assignments.Building
          |> Ash.Changeset.for_create(
            :create,
            %{
              name: "#{name} Hall",
              location: Faker.Address.country(),
              floors: trunc(floors),
              rooms: trunc(rooms_per),
              tenant_id: actor.tenant_id
            },
            actor: actor,
            tenant: tenant
          )
          |> HousingApp.Assignments.create()

        generate_rooms(building.id, floors, rooms_per_floor, products, tenant: tenant, actor: actor)
      end)
    end
  end

  defp generate_rooms(building_id, floors, rooms_per_floor, products, tenant: tenant, actor: actor) do
    Enum.map(1..floors, fn floor ->
      Enum.map(1..rooms_per_floor, fn room ->
        {:ok, room} =
          HousingApp.Assignments.Room
          |> Ash.Changeset.for_create(
            :create,
            %{
              name: "Room #{floor * 1000 + room}",
              floor: floor,
              building_id: building_id,
              max_capacity: :rand.uniform(3),
              product_id: products |> Enum.take_random(1) |> List.first() |> Map.get(:id),
              tenant_id: actor.tenant_id
            },
            actor: actor,
            tenant: tenant
          )
          |> HousingApp.Assignments.create()

        generate_beds(room, tenant: tenant, actor: actor)
      end)
    end)
  end

  defp generate_beds(room, tenant: tenant, actor: actor) do
    Enum.map(1..room.max_capacity, fn bed ->
      {:ok, _bed} =
        HousingApp.Assignments.Bed
        |> Ash.Changeset.for_create(
          :create,
          %{name: "Bed #{bed}", room_id: room.id, product_id: room.product_id, tenant_id: actor.tenant_id},
          actor: actor,
          tenant: tenant
        )
        |> HousingApp.Assignments.create()
    end)
  end
end
