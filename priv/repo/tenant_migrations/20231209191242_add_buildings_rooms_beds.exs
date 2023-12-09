defmodule HousingApp.Repo.TenantMigrations.AddBuildingsRoomsBeds do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:rooms, primary_key: false, prefix: prefix()) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :name, :text, null: false
      add :floor, :bigint, null: false, default: 1
      add :block, :text, null: false, default: ""
      add :max_capacity, :bigint, null: false, default: 0
      add :data, :map, null: false, default: %{}
      add :created_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :archived_at, :utc_datetime_usec

      add :tenant_id,
          references(:tenants,
            column: :id,
            name: "rooms_tenant_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false

      add :building_id, :uuid, null: false
    end

    create table(:buildings, primary_key: false, prefix: prefix()) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
    end

    alter table(:rooms, prefix: prefix()) do
      modify :building_id,
             references(:buildings,
               column: :id,
               name: "rooms_building_id_fkey",
               type: :uuid,
               prefix: prefix()
             )
    end

    create unique_index(:rooms, [:building_id, :name],
             name: "rooms_unique_by_building_and_name_index"
           )

    alter table(:buildings, prefix: prefix()) do
      add :name, :text, null: false
      add :location, :text, null: false
      add :floors, :bigint, null: false, default: 1
      add :rooms, :bigint, null: false, default: 0
      add :data, :map, null: false, default: %{}
      add :created_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :archived_at, :utc_datetime_usec

      add :tenant_id,
          references(:tenants,
            column: :id,
            name: "buildings_tenant_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false
    end

    create unique_index(:buildings, [:name], name: "buildings_unique_by_name_index")

    create table(:beds, primary_key: false, prefix: prefix()) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :name, :text, null: false
      add :available_at, :utc_datetime_usec
      add :data, :map, null: false, default: %{}
      add :created_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :archived_at, :utc_datetime_usec

      add :tenant_id,
          references(:tenants,
            column: :id,
            name: "beds_tenant_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false

      add :room_id,
          references(:rooms,
            column: :id,
            name: "beds_room_id_fkey",
            type: :uuid,
            prefix: prefix()
          ),
          null: false
    end

    create unique_index(:beds, [:room_id, :name], name: "beds_unique_by_room_and_name_index")
  end

  def down do
    drop_if_exists unique_index(:beds, [:room_id, :name],
                     name: "beds_unique_by_room_and_name_index"
                   )

    drop constraint(:beds, "beds_tenant_id_fkey")

    drop constraint(:beds, "beds_room_id_fkey")

    drop table(:beds, prefix: prefix())

    drop_if_exists unique_index(:buildings, [:name], name: "buildings_unique_by_name_index")

    drop constraint(:buildings, "buildings_tenant_id_fkey")

    alter table(:buildings, prefix: prefix()) do
      remove :tenant_id
      remove :archived_at
      remove :updated_at
      remove :created_at
      remove :data
      remove :rooms
      remove :floors
      remove :location
      remove :name
    end

    drop_if_exists unique_index(:rooms, [:building_id, :name],
                     name: "rooms_unique_by_building_and_name_index"
                   )

    drop constraint(:rooms, "rooms_building_id_fkey")

    alter table(:rooms, prefix: prefix()) do
      modify :building_id, :uuid
    end

    drop table(:buildings, prefix: prefix())

    drop constraint(:rooms, "rooms_tenant_id_fkey")

    drop table(:rooms, prefix: prefix())
  end
end