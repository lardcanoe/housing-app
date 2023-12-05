defmodule HousingApp.Repo.TenantMigrations.CreateGinIndexForProfileData do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    drop_if_exists index(:profiles, ["roles"], name: "profiles_roles_index")

    create index(:profiles, ["data"], using: "GIN")
  end

  def down do
    drop_if_exists index(:profiles, ["data"], name: "profiles_data_index")

    create index(:profiles, ["roles"], using: "GIN")
  end
end
