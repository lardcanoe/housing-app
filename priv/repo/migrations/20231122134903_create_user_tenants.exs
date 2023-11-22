defmodule HousingApp.Repo.Migrations.CreateUserTenants do
  use Ecto.Migration

  def change do
    create table(:user_tenants, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :binary_id), null: false

      add :role, :string, null: false, default: "user"

      timestamps(type: :utc_datetime)
    end

    create index(:user_tenants, [:tenant_id])
    create index(:user_tenants, [:user_id])
    create unique_index(:user_tenants, [:tenant_id, :user_id])
  end
end
