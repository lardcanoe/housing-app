defmodule HousingApp.Repo do
  use Ecto.Repo,
    otp_app: :housing_app,
    adapter: Ecto.Adapters.Postgres
end
