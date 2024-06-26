defmodule HousingApp.Repo.Migrations.AddArchival do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:user_tenants) do
      add :archived_at, :utc_datetime_usec
    end

    alter table(:tenants) do
      add :archived_at, :utc_datetime_usec
    end
  end

  def down do
    alter table(:tenants) do
      remove :archived_at
    end

    alter table(:user_tenants) do
      remove :archived_at
    end
  end
end
