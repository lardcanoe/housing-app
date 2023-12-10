defmodule HousingAppWeb.Live.Assignments.Rooms.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Rooms</h1>

    <.table id="rooms" rows={@rooms} pagination={false} row_id={fn row -> "rooms-row-#{row.id}" end}>
      <:button>
        <svg
          class="h-3.5 w-3.5 mr-2"
          fill="currentColor"
          viewbox="0 0 20 20"
          xmlns="http://www.w3.org/2000/svg"
          aria-hidden="true"
        >
          <path
            clip-rule="evenodd"
            fill-rule="evenodd"
            d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
          />
        </svg>
        <.link patch={~p"/assignments/rooms/new"}>
          Add room
        </.link>
      </:button>
      <:col :let={room} :if={@current_user.role == :platform_admin} label="id">
        <%= room.id %>
      </:col>
      <:col :let={room} label="building">
        <%= room.building.name %>
      </:col>
      <:col :let={room} label="name">
        <.link patch={~p"/assignments/rooms/#{room.id}"}><%= room.name %></.link>
      </:col>
      <:col :let={room} label="floor">
        <%= room.floor %>
      </:col>
      <:col :let={room} label="block">
        <%= room.block %>
      </:col>
      <:col :let={room} label="max capacity">
        <%= room.max_capacity %>
      </:col>
      <:action :let={room}>
        <.link
          patch={~p"/assignments/rooms/#{room.id}/edit"}
          class="block py-2 px-4 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
        >
          Edit
        </.link>
      </:action>
    </.table>
    """
  end

  def mount(_params, _session, socket) do
    case fetch_rooms(socket) do
      {:ok, rooms} ->
        {:ok, assign(socket, rooms: rooms, sidebar: :assignments, page_title: "Rooms")}

      _ ->
        {:ok,
         socket
         |> assign(rooms: [], sidebar: :assignments, page_title: "Rooms")
         |> put_flash(:error, "Error loading rooms.")}
    end
  end

  def handle_params(_params, _url, socket) do
    case fetch_rooms(socket) do
      {:ok, rooms} ->
        {:noreply, assign(socket, rooms: rooms, sidebar: :assignments, page_title: "Rooms")}

      _ ->
        {:noreply,
         socket
         |> assign(rooms: [], sidebar: :assignments, page_title: "Rooms")
         |> put_flash(:error, "Error loading rooms.")}
    end
  end

  defp fetch_rooms(%{
         assigns: %{current_user_tenant: current_user_tenant, current_tenant: current_tenant}
       }) do
    case HousingApp.Assignments.Room.list(actor: current_user_tenant, tenant: current_tenant) do
      {:ok, rooms} -> {:ok, rooms}
      _ -> {:error, []}
    end
  end
end
