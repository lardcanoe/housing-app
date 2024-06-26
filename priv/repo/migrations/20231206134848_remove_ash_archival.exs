defmodule HousingApp.Repo.Migrations.RemoveAshArchival do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    drop_if_exists unique_index(:user_tenants, [:tenant_id, :user_id],
                     name: "user_tenants_unique_user_and_tenant_index"
                   )

    create unique_index(:user_tenants, [:user_id, :tenant_id],
             name: "user_tenants_unique_user_and_tenant_index"
           )
  end

  def down do
    drop_if_exists unique_index(:user_tenants, [:user_id, :tenant_id],
                     name: "user_tenants_unique_user_and_tenant_index"
                   )

    create unique_index(:user_tenants, [:tenant_id, :user_id],
             where: "archived_at IS NULL",
             name: "user_tenants_unique_user_and_tenant_index"
           )
  end
end
