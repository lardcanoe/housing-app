defmodule HousingApp.Repo.TenantMigrations.CreateCommonQueriesTable do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:common_queries, primary_key: false, prefix: prefix()) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :name, :text, null: false
      add :description, :text, null: false, default: ""
      add :resource, :text, null: false
      add :filter, :map, null: false, default: %{}
      add :created_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :archived_at, :utc_datetime_usec
    end

    alter table(:applications, prefix: prefix()) do
      add :conditions, {:array, :map}, null: false, default: []
    end
  end

  def down do
    alter table(:applications, prefix: prefix()) do
      remove :conditions
    end

    drop table(:common_queries, prefix: prefix())
  end
end