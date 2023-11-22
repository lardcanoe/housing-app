defmodule HousingApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false
      add :password_hash, :string
      add :role, :string, null: false, default: "user"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
  end
end
