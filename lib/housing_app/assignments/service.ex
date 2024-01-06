defmodule HousingApp.Assignments.Service do
  @moduledoc false

  require Logger

  def upsert_bed_booking(application_submission, bed_id, actor: actor, tenant: tenant) do
    case get_booking(application_submission, actor: actor, tenant: tenant) do
      {:ok, %HousingApp.Assignments.Booking{} = booking} ->
        update_bed_booking(booking, bed_id, actor: actor, tenant: tenant)

      _ ->
        create_bed_booking(application_submission, nil, bed_id, actor.id, actor: actor, tenant: tenant)
    end
  end

  def upsert_roommate_booking(application_submission, roommate_group_id, room_id, actor: actor, tenant: tenant) do
    # FUTURE: Get available beds of the room, not just what is in the database
    with {:ok, group} <-
           HousingApp.Assignments.RoommateGroup.get_by_id(roommate_group_id,
             actor: actor,
             tenant: tenant,
             load: [members: [:user_tenant]]
           ),
         {:ok, room} <- get_room(room_id, actor: actor, tenant: tenant),
         pairs when length(group.members) <= length(room.beds) <- Enum.zip(group.members, room.beds) do
      application_id = application_submission.application_id
      created_by_id = actor.id

      Enum.map(pairs, fn {roommate, bed} ->
        upsert_roommate_booking_for(application_id, roommate_group_id, bed, created_by_id,
          actor: roommate.user_tenant,
          tenant: tenant
        )
      end)
    else
      _ -> {:error, nil}
    end
  end

  defp upsert_roommate_booking_for(application_id, roommate_group_id, bed, created_by_id,
         actor: user_tenant,
         tenant: tenant
       ) do
    Logger.info("Roommate booking for user_tenant=#{user_tenant.id} and bed=#{bed.id}")

    roommate_submission = load_submission_for(application_id, actor: user_tenant, tenant: tenant)

    case get_booking(roommate_submission, actor: user_tenant, tenant: tenant) do
      {:ok, %HousingApp.Assignments.Booking{} = booking} ->
        update_bed_booking(booking, bed.id, actor: user_tenant, tenant: tenant)

      _ ->
        create_bed_booking(roommate_submission, roommate_group_id, bed.id, created_by_id,
          actor: user_tenant,
          tenant: tenant
        )
    end
  end

  defp load_submission_for(application_id, actor: user_tenant, tenant: tenant) do
    case HousingApp.Management.ApplicationSubmission.get_submission(application_id, user_tenant.id,
           actor: user_tenant,
           tenant: tenant
         ) do
      {:ok, submission} ->
        submission

      {:error, _} ->
        Logger.info("Starting submission application_id=#{application_id} for user_tenant=#{user_tenant.id}")

        HousingApp.Management.ApplicationSubmission.start!(
          %{application_id: application_id},
          actor: user_tenant,
          tenant: tenant
        )
    end
  end

  defp get_booking(application_submission, actor: actor, tenant: tenant) do
    HousingApp.Assignments.Booking.get_for_application_submission(
      application_submission.id,
      actor: actor,
      tenant: tenant,
      not_found_error?: false
    )
  end

  defp create_bed_booking(application_submission, roommate_group_id, bed_id, created_by_id,
         actor: actor,
         tenant: tenant
       ) do
    with {:ok, application_submission} <-
           HousingApp.Management.load(application_submission, [application: :time_period], actor: actor, tenant: tenant),
         {:ok, profile} <- HousingApp.Management.Profile.get_mine(actor: actor, tenant: tenant),
         {:ok, bed} <- get_bed(bed_id, actor: actor, tenant: tenant) do
      HousingApp.Assignments.Booking
      |> Ash.Changeset.for_create(
        :new,
        %{
          application_submission_id: application_submission.id,
          bed_id: bed_id,
          profile_id: profile.id,
          product_id: bed.room.product_id,
          start_at: application_submission.application.time_period.start_at,
          end_at: application_submission.application.time_period.end_at,
          roommate_group_id: roommate_group_id,
          created_by_id: created_by_id
        },
        actor: actor,
        tenant: tenant
      )
      |> HousingApp.Assignments.create()
    else
      failure ->
        Logger.error("Failed to create booking...")
        dbg(failure)
        {:error, nil}
    end
  end

  defp update_bed_booking(booking, bed_id, actor: actor, tenant: tenant) do
    if booking.bed_id != bed_id do
      case get_bed(bed_id, actor: actor, tenant: tenant) do
        {:ok, bed} ->
          booking
          |> Ash.Changeset.for_update(
            :swap_bed,
            %{
              bed_id: bed_id,
              product_id: bed.room.product_id
            },
            actor: actor,
            tenant: tenant
          )
          |> HousingApp.Assignments.update()

        failure ->
          Logger.error("Failed to update booking...")
          dbg(failure)
          {:error, nil}
      end
    else
      {:ok, booking}
    end
  end

  defp get_bed(bed_id, actor: actor, tenant: tenant) do
    HousingApp.Assignments.Bed.get_by_id(bed_id, actor: actor, tenant: tenant)
  end

  defp get_room(room_id, actor: actor, tenant: tenant) do
    HousingApp.Assignments.Room.get_by_id(room_id, actor: actor, tenant: tenant, load: [:beds])
  end
end