defmodule HousingApp.Repo.TenantMigrations.AddStatusToApplicationSubmissions do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:application_submissions, prefix: prefix()) do
      add :status, :text, null: false, default: "started"
    end
  end

  def down do
    alter table(:application_submissions, prefix: prefix()) do
      remove :status
    end
  end
end