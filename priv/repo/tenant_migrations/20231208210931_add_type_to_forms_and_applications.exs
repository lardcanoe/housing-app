defmodule HousingApp.Repo.TenantMigrations.AddTypeToFormsAndApplications do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:forms, prefix: prefix()) do
      add :type, :text, null: false, default: ""
    end

    alter table(:applications, prefix: prefix()) do
      add :type, :text, null: false, default: ""
    end
  end

  def down do
    alter table(:applications, prefix: prefix()) do
      remove :type
    end

    alter table(:forms, prefix: prefix()) do
      remove :type
    end
  end
end