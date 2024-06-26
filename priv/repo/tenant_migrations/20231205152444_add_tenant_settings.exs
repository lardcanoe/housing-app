defmodule HousingApp.Repo.TenantMigrations.AddTenantSettings do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:tenant_settings, primary_key: false, prefix: prefix()) do
      add :namespace, :text, null: false, primary_key: true
      add :setting, :text, null: false, primary_key: true
      add :value, :text, null: false
      add :created_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
    end

    create unique_index(:tenant_settings, [:namespace, :setting],
             name: "tenant_settings_unique_namespace_setting_index"
           )
  end

  def down do
    drop_if_exists unique_index(:tenant_settings, [:namespace, :setting],
                     name: "tenant_settings_unique_namespace_setting_index"
                   )

    drop table(:tenant_settings, prefix: prefix())
  end
end