defmodule HousingAppWeb.Components.Assignments.SelectBed do
  @moduledoc false

  use HousingAppWeb, :live_component

  # import HousingAppWeb.CoreComponents, only: [icon: 1]

  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true
  attr :data, :any, required: true
  attr :submission, :any, required: true

  def render(assigns) do
    ~H"""
    <div>
      <.simple_form for={@form} phx-change="validate" phx-submit="submit" phx-target={@myself}>
        <.input
          type="select"
          field={@form[:roommate_group_id]}
          options={@roommate_group_options}
          label="Roommate Group"
          required
          {if(@booking, do: [{"disabled",""}])}
        />

        <.async_result :let={rooms} :if={@selection == :room} assign={@rooms}>
          <:loading>
            <.input type="select" field={@form[:room_id]} options={[]} label="Room" prompt="Loading rooms..." disabled />
          </:loading>
          <:failed :let={reason}><%= reason %></:failed>
          <.input
            type="select"
            field={@form[:room_id]}
            options={rooms}
            label="Room"
            prompt="Select a room..."
            required
            {if(@booking, do: [{"disabled",""}])}
          />
        </.async_result>

        <.async_result :let={beds} :if={@selection == :bed} assign={@beds}>
          <:loading>
            <.input type="select" field={@form[:bed_id]} options={[]} label="Bed" prompt="Loading beds..." disabled />
          </:loading>
          <:failed :let={reason}><%= reason %></:failed>
          <.input
            type="select"
            field={@form[:bed_id]}
            options={beds}
            label="Bed"
            prompt="Select a bed..."
            required
            {if(@booking, do: [{"disabled",""}])}
          />
        </.async_result>

        <h1 :if={@booking} class="mb-2 text-xl font-bold tracking-tight text-gray-900 dark:text-white">
          Current bed selection: <%= @booking.bed.room.building.name %> <%= @booking.bed.room.name %>, Bed <%= @booking.bed.name %>
        </h1>

        <:actions>
          <.button :if={@booking}>Accept bed selection</.button>
          <.button :if={is_nil(@booking)}>Next</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, roommate_group_id: "", selection: :none)}
  end

  def update(params, socket) do
    {:ok,
     socket
     |> assign(params)
     |> load_booking()
     |> load_form()
     |> load_roommate_groups()
     |> refresh_beds()}
  end

  def handle_event(
        "validate",
        %{"_target" => ["form", "roommate_group_id"], "form" => %{"roommate_group_id" => roommate_group_id}},
        socket
      ) do
    {:noreply, socket |> assign(roommate_group_id: roommate_group_id) |> refresh_beds()}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  # User has accepted their roommate bed selection
  def handle_event("submit", %{}, %{assigns: %{booking: booking}} = socket) when not is_nil(booking) do
    send(
      self(),
      {:component_submit,
       %{
         "roommate_group_id" => booking.roommate_group_id,
         "room_id" => booking.bed.room_id,
         "bed_id" => booking.bed_id
       }}
    )

    {:noreply, socket}
  end

  def handle_event("submit", %{"form" => data}, socket) do
    # TODO: create_booking should be an async task, and should run in a txn
    case create_booking(data, socket) do
      {:ok, _booking} ->
        send(self(), {:component_submit, data})
        {:noreply, socket}

      results when is_list(results) ->
        # TODO: Check that all are "ok: Booking" and not "error: ..."
        send(self(), {:component_submit, data})
        {:noreply, socket}

      {:error, errors} ->
        dbg(errors)
        {:noreply, put_flash(socket, :error, "Error creating booking.")}
    end
  end

  defp load_booking(socket) do
    %{submission: submission, data: data, current_user_tenant: current_user_tenant, current_tenant: tenant} =
      socket.assigns

    case HousingApp.Assignments.Booking.get_for_application_submission(
           submission.id,
           actor: current_user_tenant,
           tenant: tenant,
           load: [bed: [room: [:building]]],
           not_found_error?: false
         ) do
      {:ok, %HousingApp.Assignments.Booking{} = booking} ->
        assign(socket,
          booking: booking,
          roommate_group_id: booking.roommate_group_id,
          room_id: booking.bed.room_id,
          bed_id: booking.bed_id
        )

      _ ->
        assign(socket, booking: nil, roommate_group_id: data["roommate_group_id"])
    end
  end

  defp load_form(%{assigns: %{booking: booking}} = socket) when not is_nil(booking) do
    form_data =
      Map.merge(
        %{
          "roommate_group_id" => booking.roommate_group_id,
          "room_id" => booking.bed.room_id,
          "bed_id" => booking.bed_id
        },
        socket.assigns.data
      )

    assign(socket, form: to_form(form_data, as: "form"))
  end

  defp load_form(socket) do
    assign(socket, form: to_form(socket.assigns.data, as: "form"))
  end

  defp load_roommate_groups(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    roommate_groups =
      [actor: current_user_tenant, tenant: tenant, load: [roommate_group: [members: [user_tenant: [:user]]]]]
      |> HousingApp.Assignments.Roommate.list_mine!()
      |> Enum.map(& &1.roommate_group)

    roommate_group_options =
      roommate_groups
      |> Enum.map(fn p -> {"#{p.name} (#{Enum.count(p.members)} members)", p.id} end)
      |> Enum.sort_by(fn {name, _} -> name end)

    roommate_group_options = [{"None", "none"}] ++ roommate_group_options

    assign(socket, roommate_groups: roommate_groups, roommate_group_options: roommate_group_options)
  end

  defp refresh_beds(socket) do
    %{roommate_group_id: roommate_group_id, roommate_groups: roommate_groups} = socket.assigns

    selected = Enum.find(roommate_groups, &(&1.id == roommate_group_id))

    find_beds_for_group(socket, selected)
  end

  defp find_beds_for_group(socket, nil) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    socket
    |> assign(selection: :bed)
    |> assign_async([:beds], fn ->
      beds =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Assignments.Bed.list!()
        |> Enum.map(&{"#{&1.room.building.name} / #{&1.room.name} / #{&1.name}", &1.id})
        |> Enum.sort_by(fn {name, _} -> name end)

      {:ok, %{beds: beds}}
    end)
  end

  defp find_beds_for_group(socket, roommate_group) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    min_capacity = Enum.count(roommate_group.members)

    socket
    |> assign(selection: :room)
    |> assign_async([:rooms], fn ->
      rooms =
        [actor: current_user_tenant, tenant: tenant, load: [:beds]]
        |> HousingApp.Assignments.Room.list!()
        |> Enum.filter(fn r -> Enum.count(r.beds) >= min_capacity end)
        |> Enum.map(&{"#{&1.building.name} / #{&1.name} (#{Enum.count(&1.beds)} beds)", &1.id})
        |> Enum.sort_by(fn {name, _} -> name end)

      {:ok, %{rooms: rooms}}
    end)
  end

  defp create_booking(%{"bed_id" => bed_id}, socket) when is_binary(bed_id) and bed_id != "" do
    %{submission: submission, current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    HousingApp.Assignments.Service.upsert_bed_booking(
      submission,
      bed_id,
      actor: current_user_tenant,
      tenant: tenant
    )
  end

  defp create_booking(%{"roommate_group_id" => roommate_group_id, "room_id" => room_id}, socket)
       when is_binary(room_id) and room_id != "" and is_binary(roommate_group_id) and roommate_group_id != "" do
    %{submission: submission, current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    HousingApp.Assignments.Service.upsert_roommate_booking(
      submission,
      roommate_group_id,
      room_id,
      actor: current_user_tenant,
      tenant: tenant
    )
  end
end
