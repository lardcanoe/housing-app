defmodule HousingApp.Repo.Migrations.ChangeRoleFields do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:users) do
      add :role, :text, null: false, default: "user"
    end

    alter table(:user_tenants) do
      modify :role, :text, default: "user"
    end
  end

  def down do
    alter table(:user_tenants) do
      modify :role, :text, default: nil
    end

    alter table(:users) do
      remove :role
    end
  end
end
