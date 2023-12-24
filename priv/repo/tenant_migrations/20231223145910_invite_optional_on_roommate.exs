defmodule HousingApp.Repo.TenantMigrations.InviteOptionalOnRoommate do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:roommates, prefix: prefix()) do
      modify :roommate_invite_id, :uuid, null: true
    end
  end

  def down do
    alter table(:roommates, prefix: prefix()) do
      modify :roommate_invite_id, :uuid, null: false
    end
  end
end