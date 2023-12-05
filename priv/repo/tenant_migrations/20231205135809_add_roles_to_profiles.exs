defmodule HousingApp.Repo.TenantMigrations.AddRolesToProfiles do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:profiles, prefix: prefix()) do
      add :roles, {:array, :text}, null: false, default: []
    end

    create index(:profiles, ["roles"], using: "GIN")
  end

  def down do
    drop_if_exists index(:profiles, ["roles"], name: "profiles_roles_index")

    alter table(:profiles, prefix: prefix()) do
      remove :roles
    end
  end
end
