defmodule HousingApp.Assignments.Booking do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api],
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id

    attribute :start_at, :date do
      allow_nil? false
    end

    attribute :end_at, :date do
      allow_nil? false
    end

    attribute :data, :map do
      default %{}
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :archived_at, :utc_datetime_usec do
      allow_nil? true
    end
  end

  admin do
    show?(true)
  end

  relationships do
    # Tenant is duplicate data, but makes it safer and easier to do data dumps
    belongs_to :tenant, HousingApp.Accounts.Tenant do
      api HousingApp.Accounts
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :bed, HousingApp.Assignments.Bed do
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :profile, HousingApp.Management.Profile do
      api HousingApp.Management
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :product, HousingApp.Accounting.Product do
      api HousingApp.Accounting
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :application_submission, HousingApp.Management.ApplicationSubmission do
      api HousingApp.Management
      attribute_writable? true
    end
  end

  policies do
    bypass always() do
      authorize_if HousingApp.Checks.IsPlatformAdmin
      authorize_if HousingApp.Checks.IsTenantAdmin
    end
  end

  postgres do
    table "bookings"
    repo HousingApp.Repo

    custom_indexes do
      index [:bed_id]
    end

    custom_indexes do
      index [:profile_id]
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :new do
      accept [:bed_id, :profile_id, :product_id, :application_submission_id, :start_at, :end_at, :data]
      change set_attribute(:tenant_id, actor(:tenant_id))
    end

    read :list do
      prepare build(
                load: [
                  :product,
                  :application_submission,
                  profile: [user_tenant: [:user]],
                  bed: [room: [:building]]
                ]
              )

      filter expr(is_nil(archived_at))
    end

    read :list_by_room do
      argument :room_id, :uuid do
        allow_nil? false
      end

      prepare build(load: [:product, profile: [user_tenant: [:user]], bed: [room: [:building]]])
      filter expr(bed.room_id == ^arg(:room_id) and is_nil(archived_at))
    end

    read :list_by_bed do
      argument :bed_id, :uuid do
        allow_nil? false
      end

      prepare build(load: [:product, profile: [user_tenant: [:user]], bed: [room: [:building]]])
      filter expr(bed_id == ^arg(:bed_id) and is_nil(archived_at))
    end

    read :list_by_profile do
      argument :profile_id, :uuid do
        allow_nil? false
      end

      prepare build(load: [:product, profile: [user_tenant: [:user]], bed: [room: [:building]]])
      filter expr(profile_id == ^arg(:profile_id) and is_nil(archived_at))
    end

    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      prepare build(
                load: [:product, :application_submission, profile: [user_tenant: [:user]], bed: [room: [:building]]]
              )

      get? true

      filter expr(id == ^arg(:id) and is_nil(archived_at))
    end
  end

  code_interface do
    define_for HousingApp.Assignments

    define :new
    define :list
    define :list_by_room, args: [:room_id]
    define :list_by_bed, args: [:bed_id]
    define :list_by_profile, args: [:profile_id]
    define :get_by_id, args: [:id]
  end

  identities do
    identity :unique_by_bed_profile_start_at, [:bed_id, :profile_id, :start_at]
  end

  validations do
    validate compare(:end_at, greater_than: :start_at)
    # FUTURE: , message: "must be a date after %{start_at}."
  end

  multitenancy do
    strategy :context
  end
end
