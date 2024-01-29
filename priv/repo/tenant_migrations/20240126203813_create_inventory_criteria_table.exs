defmodule HousingApp.Repo.TenantMigrations.CreateInventoryCriteriaTable do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:inventory_criteria, primary_key: false, prefix: prefix()) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :tenant_id,
          references(:tenants,
            column: :id,
            name: "inventory_criteria_tenant_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false
      add :name, :text, null: false
      add :description, :text, default: ""
      add :conditions, {:array, :map}, null: false, default: []
      add :filters, {:array, :map}, null: false, default: []
      add :created_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :archived_at, :utc_datetime_usec
    end
  end

  def down do
    drop constraint(:inventory_criteria, "inventory_criteria_tenant_id_fkey")

    drop table(:inventory_criteria, prefix: prefix())
  end
end