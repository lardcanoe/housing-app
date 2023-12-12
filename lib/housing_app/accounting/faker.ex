defmodule HousingApp.Accounting.Faker do
  @moduledoc """
  Generates fake data for Accounting.
  """

  def generate(%{"products" => "0"}, _opts) do
    []
  end

  def generate(%{"products" => products}, [tenant: tenant, actor: actor] = _opts) do
    products = String.to_integer(products)

    Faker.Util.sample_uniq(products, &Faker.Commerce.product_name/0)
    |> Enum.map(fn name ->
      HousingApp.Accounting.Product
      |> Ash.Changeset.for_create(
        :create,
        %{name: name, rate: Faker.Commerce.price() * 100, tenant_id: actor.tenant_id},
        actor: actor,
        tenant: tenant
      )
      |> HousingApp.Accounting.create()
    end)
  end
end
