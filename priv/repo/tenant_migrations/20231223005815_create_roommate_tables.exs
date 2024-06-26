defmodule HousingApp.Repo.TenantMigrations.CreateRoommateTables do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:roommates, primary_key: false, prefix: prefix()) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :tenant_id,
          references(:tenants,
            column: :id,
            name: "roommates_tenant_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false

      add :roommate_group_id, :uuid, null: false
      add :user_tenant_id, :uuid, null: false
      add :roommate_invite_id, :uuid, null: false
      add :created_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :archived_at, :utc_datetime_usec
    end

    create index(:roommates, ["roommate_group_id"])

    create index(:roommates, ["user_tenant_id"])

    create table(:roommate_invites, primary_key: false, prefix: prefix()) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :tenant_id,
          references(:tenants,
            column: :id,
            name: "roommate_invites_tenant_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false

      add :roommate_group_id, :uuid, null: false
      add :user_tenant_id, :uuid, null: false
      add :invited_by_id, :uuid
      add :status, :text, null: false, default: "pending"
      add :created_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :archived_at, :utc_datetime_usec
    end

    create index(:roommate_invites, ["roommate_group_id"])

    create index(:roommate_invites, ["user_tenant_id"])

    create table(:roommate_groups, primary_key: false, prefix: prefix()) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
    end

    alter table(:roommates, prefix: prefix()) do
      modify :roommate_group_id,
             references(:roommate_groups,
               column: :id,
               name: "roommates_roommate_group_id_fkey",
               type: :uuid,
               prefix: prefix()
             )

      modify :user_tenant_id,
             references(:user_tenants,
               column: :id,
               name: "roommates_user_tenant_id_fkey",
               type: :uuid,
               prefix: "public"
             )

      modify :roommate_invite_id,
             references(:roommate_invites,
               column: :id,
               name: "roommates_roommate_invite_id_fkey",
               type: :uuid,
               prefix: prefix()
             )
    end

    create unique_index(:roommates, [:roommate_group_id, :user_tenant_id],
             name: "roommates_unique_by_group_and_user_index"
           )

    alter table(:roommate_invites, prefix: prefix()) do
      modify :roommate_group_id,
             references(:roommate_groups,
               column: :id,
               name: "roommate_invites_roommate_group_id_fkey",
               type: :uuid,
               prefix: prefix()
             )

      modify :user_tenant_id,
             references(:user_tenants,
               column: :id,
               name: "roommate_invites_user_tenant_id_fkey",
               type: :uuid,
               prefix: "public"
             )

      modify :invited_by_id,
             references(:user_tenants,
               column: :id,
               name: "roommate_invites_invited_by_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    create unique_index(:roommate_invites, [:roommate_group_id, :user_tenant_id],
             name: "roommate_invites_unique_by_group_and_user_index"
           )

    alter table(:roommate_groups, prefix: prefix()) do
      add :name, :text, null: false
      add :tenant_id,
          references(:tenants,
            column: :id,
            name: "roommate_groups_tenant_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false

      add :created_by_id,
          references(:user_tenants,
            column: :id,
            name: "roommate_groups_created_by_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false
      add :created_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :archived_at, :utc_datetime_usec
    end

    create index(:roommate_groups, ["created_by_id"])
  end

  def down do
    drop constraint(:roommate_groups, "roommate_groups_tenant_id_fkey")

    drop constraint(:roommate_groups, "roommate_groups_created_by_id_fkey")

    drop_if_exists index(:roommate_groups, ["created_by_id"],
                     name: "roommate_groups_created_by_id_index"
                   )

    alter table(:roommate_groups, prefix: prefix()) do
      remove :created_by_id
      remove :tenant_id
      remove :archived_at
      remove :updated_at
      remove :created_at
      remove :name
    end

    drop_if_exists unique_index(:roommate_invites, [:roommate_group_id, :user_tenant_id],
                     name: "roommate_invites_unique_by_group_and_user_index"
                   )

    drop constraint(:roommate_invites, "roommate_invites_roommate_group_id_fkey")

    drop constraint(:roommate_invites, "roommate_invites_user_tenant_id_fkey")

    drop constraint(:roommate_invites, "roommate_invites_invited_by_id_fkey")

    alter table(:roommate_invites, prefix: prefix()) do
      modify :invited_by_id, :uuid
      modify :user_tenant_id, :uuid
      modify :roommate_group_id, :uuid
    end

    drop_if_exists unique_index(:roommates, [:roommate_group_id, :user_tenant_id],
                     name: "roommates_unique_by_group_and_user_index"
                   )

    drop constraint(:roommates, "roommates_roommate_group_id_fkey")

    drop constraint(:roommates, "roommates_user_tenant_id_fkey")

    drop constraint(:roommates, "roommates_roommate_invite_id_fkey")

    alter table(:roommates, prefix: prefix()) do
      modify :roommate_invite_id, :uuid
      modify :user_tenant_id, :uuid
      modify :roommate_group_id, :uuid
    end

    drop table(:roommate_groups, prefix: prefix())

    drop constraint(:roommate_invites, "roommate_invites_tenant_id_fkey")

    drop_if_exists index(:roommate_invites, ["user_tenant_id"],
                     name: "roommate_invites_user_tenant_id_index"
                   )

    drop_if_exists index(:roommate_invites, ["roommate_group_id"],
                     name: "roommate_invites_roommate_group_id_index"
                   )

    drop table(:roommate_invites, prefix: prefix())

    drop constraint(:roommates, "roommates_tenant_id_fkey")

    drop_if_exists index(:roommates, ["user_tenant_id"], name: "roommates_user_tenant_id_index")

    drop_if_exists index(:roommates, ["roommate_group_id"],
                     name: "roommates_roommate_group_id_index"
                   )

    drop table(:roommates, prefix: prefix())
  end
end
