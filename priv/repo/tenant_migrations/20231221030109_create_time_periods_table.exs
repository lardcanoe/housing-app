defmodule HousingApp.Repo.TenantMigrations.CreateTimePeriodsTable do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:time_periods, primary_key: false, prefix: prefix()) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :name, :text, null: false
      add :start_at, :date, null: false
      add :end_at, :date, null: false
      add :status, :text, null: false, default: "pending"
      add :created_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
    end

    create unique_index(:time_periods, [:name], name: "time_periods_unique_name_index")

    alter table(:applications, prefix: prefix()) do
      add :time_period_id,
          references(:time_periods,
            column: :id,
            name: "applications_time_period_id_fkey",
            type: :uuid,
            prefix: prefix()
          )
    end
  end

  def down do
    drop constraint(:applications, "applications_time_period_id_fkey")

    alter table(:applications, prefix: prefix()) do
      remove :time_period_id
    end

    drop_if_exists unique_index(:time_periods, [:name], name: "time_periods_unique_name_index")

    drop table(:time_periods, prefix: prefix())
  end
end