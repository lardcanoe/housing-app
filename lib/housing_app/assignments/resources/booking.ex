defmodule HousingApp.Assignments.Booking do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api],
    authorizers: [Ash.Policy.Authorizer]

  import Ecto.Query, only: [from: 2]

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
      private? true
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

    belongs_to :roommate_group, HousingApp.Assignments.RoommateGroup do
      attribute_writable? true
    end

    belongs_to :created_by, HousingApp.Accounts.UserTenant do
      api HousingApp.Accounts
      attribute_writable? true
    end
  end

  policies do
    bypass always() do
      authorize_if HousingApp.Checks.IsPlatformAdmin
      authorize_if HousingApp.Checks.IsTenantAdmin
    end

    policy action(:get_for_application_submission) do
      authorize_if relates_to_actor_via([:profile, :user_tenant])
    end

    policy action(:new) do
      authorize_if always()
    end

    policy action(:swap_bed) do
      authorize_if relates_to_actor_via([:profile, :user_tenant])
    end

    policy action_type(:read) do
      # Overly permissive since RAs need to read
      authorize_if always()
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
    defaults [:create, :read, :update]

    create :new do
      accept [
        :bed_id,
        :profile_id,
        :product_id,
        :application_submission_id,
        :start_at,
        :end_at,
        :data,
        :roommate_group_id,
        :created_by_id
      ]

      change set_attribute(:tenant_id, actor(:tenant_id))
    end

    update :swap_bed do
      accept [:bed_id, :product_id]
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

    read :list_for_assignments do
      prepare build(
                load: [
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

    read :get_for_application_submission do
      argument :application_submission_id, :uuid do
        allow_nil? false
      end

      get? true

      filter expr(application_submission_id == ^arg(:application_submission_id) and is_nil(archived_at))
    end

    action :stats_by_time_period, {:array, :struct} do
      run fn input, context ->
        from(b in __MODULE__,
          join: sub in assoc(b, :application_submission),
          join: app in assoc(sub, :application),
          join: tp in assoc(app, :time_period),
          where:
            b.tenant_id == ^context.actor.tenant_id and
              is_nil(b.archived_at) and
              is_nil(sub.archived_at) and
              sub.status == ^:completed and
              is_nil(app.archived_at) and
              app.status == ^:approved,
          group_by: [tp.id, tp.name, app.id, app.name],
          select: [tp.id, tp.name, app.id, app.name, count()]
        )
        |> HousingApp.Repo.all(prefix: input.tenant)
        |> Enum.map(fn [tp_id, tp_name, app_id, app_name, count] ->
          %{time_period: %{id: tp_id, name: tp_name}, application: %{id: app_id, name: app_name}, count: count}
        end)
        |> then(&{:ok, &1})
      end
    end

    destroy :archive do
      primary? true
      soft? true
      change set_attribute(:archived_at, &DateTime.utc_now/0)
    end
  end

  code_interface do
    define_for HousingApp.Assignments

    define :new
    define :swap_bed
    define :list
    define :list_by_room, args: [:room_id]
    define :list_by_bed, args: [:bed_id]
    define :list_by_profile, args: [:profile_id]
    define :get_by_id, args: [:id]
    define :get_for_application_submission, args: [:application_submission_id]
    define :stats_by_time_period
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
