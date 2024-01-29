defmodule HousingApp.Assignments.Service do
  @moduledoc false

  require Logger

  def available_rooms_for(selection_process_id, actor: actor, tenant: tenant) do
    profile =
      HousingApp.Management.Profile
      |> Ash.Query.for_read(:get_mine_for_matching, %{}, actor: actor, tenant: tenant)
      |> HousingApp.Management.read!()

    selection_process =
      HousingApp.Assignments.SelectionProcess.get_by_id!(selection_process_id, actor: actor, tenant: tenant)

    pc =
      Enum.find(selection_process.criterion, fn pc ->
        profile_matches_selection_criteria?(profile, pc.criteria)
      end)

    if pc do
      find_rooms_matching_criteria(pc.criteria, actor: actor, tenant: tenant)
    else
      # TODO: How to handle/display that there are no matching rooms?
      {:ok, []}
    end
  end

  defp profile_matches_selection_criteria?(_profile, _criteria) do
    # FUTURE: Implement
    true
  end

  defp find_rooms_matching_criteria(criteria, actor: actor, tenant: tenant) do
    # TODO: Is merging the correct approach?
    merged_filter =
      Enum.reduce(criteria.filters, %{}, fn f, acc ->
        Map.merge(acc, f.common_query.filter)
      end)

    filter_resource(HousingApp.Assignments.Room, :list, %{filter: merged_filter},
      actor: actor,
      tenant: tenant
    )
  end

  def upsert_bed_booking(application_submission, bed_id, actor: actor, tenant: tenant) do
    case get_booking(application_submission, actor: actor, tenant: tenant) do
      {:ok, %HousingApp.Assignments.Booking{} = booking} ->
        update_bed_booking(booking, bed_id, actor: actor, tenant: tenant)

      _ ->
        create_bed_booking(application_submission, nil, bed_id, actor.id, actor: actor, tenant: tenant)
    end
  end

  def upsert_room_booking(application_submission, room_id, actor: actor, tenant: tenant) do
    {:ok, room} = get_room(room_id, actor: actor, tenant: tenant)

    # FUTURE: Get the bed that is available, not just the first one
    first_bed = hd(room.beds)
    upsert_bed_booking(application_submission, first_bed.id, actor: actor, tenant: tenant)
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
         {:ok, %{id: profile_id}} <- HousingApp.Management.Profile.get_my_id(actor: actor, tenant: tenant),
         {:ok, bed} <- get_bed(bed_id, actor: actor, tenant: tenant) do
      HousingApp.Assignments.Booking
      |> Ash.Changeset.for_create(
        :new,
        %{
          application_submission_id: application_submission.id,
          bed_id: bed_id,
          profile_id: profile_id,
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

  def filter_resource(resource, read_action, nil, actor: actor, tenant: tenant) do
    resource
    |> Ash.Query.for_read(read_action, %{}, actor: actor, tenant: tenant)
    |> HousingApp.Assignments.read!()
  end

  def filter_resource(resource, read_action, common_query, actor: actor, tenant: tenant) do
    {_combinator, statement} =
      case common_query.filter do
        %{"" => predicates} -> {"and", predicates}
        %{"and" => predicates} -> {"and", predicates}
        %{"or" => predicates} -> {"or", [or: predicates]}
      end

    # TODO: I think "or" is handled wrong, might need an array of arrays, see: https://hexdocs.pm/ash/2.17.17/Ash.Filter.html#module-keyword-list-syntax
    {:ok, filter} = Ash.Filter.parse_input(resource, statement)

    resource
    |> Ash.Query.for_read(read_action, %{}, actor: actor, tenant: tenant)
    |> Ash.Query.filter_input(filter)
    |> HousingApp.Assignments.read!()
  end
end
