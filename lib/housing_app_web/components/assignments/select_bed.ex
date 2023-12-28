defmodule HousingAppWeb.Components.Assignments.SelectBed do
  @moduledoc false

  use HousingAppWeb, :live_component

  # import HousingAppWeb.CoreComponents, only: [icon: 1]

  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true
  attr :data, :any, required: true

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
        />

        <.async_result :let={beds} :if={@selection == :bed and not is_nil(@form[:roommate_group_id])} assign={@beds}>
          <:loading>
            <.input type="select" field={@form[:bed_id]} options={[]} label="Bed" prompt="Loading beds..." disabled />
          </:loading>
          <:failed :let={reason}><%= reason %></:failed>
          <.input type="select" field={@form[:bed_id]} options={beds} label="Bed" prompt="Select a bed..." required />
        </.async_result>

        <.async_result :let={rooms} :if={@selection == :room and not is_nil(@form[:roommate_group_id])} assign={@rooms}>
          <:loading>
            <.input type="select" field={@form[:room_id]} options={[]} label="Room" prompt="Loading rooms..." disabled />
          </:loading>
          <:failed :let={reason}><%= reason %></:failed>
          <.input type="select" field={@form[:room_id]} options={rooms} label="Room" prompt="Select a room..." required />
        </.async_result>

        <:actions>
          <.button>Next</.button>
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
     |> assign(roommate_group_id: params.data["roommate_group_id"])
     |> assign(form: to_form(params.data, as: "form"))
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

  def handle_event("submit", %{"form" => data}, socket) do
    send(self(), {:component_submit, data})
    {:noreply, socket}
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
end
