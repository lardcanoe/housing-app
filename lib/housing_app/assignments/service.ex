defmodule HousingApp.Assignments.Service do
  @moduledoc false
  def upsert_bed_booking(application_submission, bed_id, actor: actor, tenant: tenant) do
    case get_booking(application_submission, actor: actor, tenant: tenant) do
      {:ok, %HousingApp.Assignments.Booking{} = booking} ->
        update_booking(booking, bed_id, actor: actor, tenant: tenant)

      _ ->
        create_booking(application_submission, bed_id, actor: actor, tenant: tenant)
    end
  end

  def upsert_roommate_booking(application_submission, actor: actor, tenant: tenant) do
    # HousingApp.Assignments.Booking
  end

  defp get_booking(application_submission, actor: actor, tenant: tenant) do
    HousingApp.Assignments.Booking.get_for_application_submission(
      application_submission.id,
      actor: actor,
      tenant: tenant,
      not_found_error?: false
    )
  end

  defp create_booking(application_submission, bed_id, actor: actor, tenant: tenant) do
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
          end_at: application_submission.application.time_period.end_at
        },
        actor: actor,
        tenant: tenant
      )
      |> HousingApp.Assignments.create()
    else
      failure ->
        dbg(failure)
        {:error, nil}
    end
  end

  defp update_booking(booking, bed_id, actor: actor, tenant: tenant) do
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
end
