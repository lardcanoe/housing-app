defmodule HousingApp.Repo do
  use AshPostgres.Repo, otp_app: :housing_app

  def installed_extensions() do
    ["uuid-ossp", "citext"]
  end
end
