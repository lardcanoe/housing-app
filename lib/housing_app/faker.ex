defmodule HousingApp.Faker do
  @moduledoc """
  Generates fake data for the application.
  """

  def generate(params, opts \\ []) do
    HousingApp.Accounts.Faker.generate(params, opts)

    HousingApp.Accounting.Faker.generate(params, opts)

    HousingApp.Management.Faker.generate(params, opts)

    HousingApp.Assignments.Faker.generate(params, opts)

    {:ok, []}
  rescue
    error ->
      IO.inspect(error)
      {:error, error}
  end
end
