defmodule HousingApp.Repo.TenantMigrations.AddTenantToProfiles do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:profiles, prefix: prefix()) do
      add :tenant_id,
          references(:tenants,
            column: :id,
            name: "profiles_tenant_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false
    end
  end

  def down do
    drop constraint(:profiles, "profiles_tenant_id_fkey")

    alter table(:profiles, prefix: prefix()) do
      remove :tenant_id
    end
  end
end