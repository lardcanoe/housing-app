defmodule HousingApp.Repo.TenantMigrations.AddForms do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:forms, primary_key: false, prefix: prefix()) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :name, :text, null: false
      add :description, :text, null: false, default: ""
      add :status, :text, null: false, default: "draft"
      add :json_schema, :text, null: false
      add :version, :bigint, null: false, default: 1
      add :created_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :archived_at, :utc_datetime_usec

      add :tenant_id,
          references(:tenants,
            column: :id,
            name: "forms_tenant_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false
    end
  end

  def down do
    drop constraint(:forms, "forms_tenant_id_fkey")

    drop table(:forms, prefix: prefix())
  end
end
