defmodule HousingAppWeb.Live.Assignments.Bookings.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Bookings</h1>

    <.table id="bookings" rows={@bookings} pagination={false} row_id={fn row -> "bookings-row-#{row.id}" end}>
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
        <.link patch={~p"/assignments/bookings/new"}>
          Add booking
        </.link>
      </:button>
      <:col :let={booking} :if={@current_user.role == :platform_admin} label="id">
        <%= booking.id %>
      </:col>
      <:col :let={booking} label="profile">
        <%= booking.profile.user_tenant.user.name %>
      </:col>
      <:col :let={booking} label="building">
        <%= booking.bed.room.building.name %>
      </:col>
      <:col :let={booking} label="room">
        <%= booking.bed.room.name %>
      </:col>
      <:col :let={booking} label="bed">
        <%= booking.bed.name %>
      </:col>
      <:col :let={booking} label="product">
        <%= booking.product.name %> ($<%= booking.product.rate %>)
      </:col>
      <:col :let={booking} label="start at">
        <%= booking.start_at %>
      </:col>
      <:col :let={booking} label="end at">
        <%= booking.end_at %>
      </:col>
      <:action :let={booking}>
        <.link
          patch={~p"/assignments/bookings/#{booking.id}/edit"}
          class="block py-2 px-4 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
        >
          Edit
        </.link>
      </:action>
    </.table>
    """
  end

  def mount(_params, _session, socket) do
    case fetch_bookings(socket) do
      {:ok, bookings} ->
        {:ok, assign(socket, bookings: bookings, sidebar: :assignments, page_title: "Bookings")}

      _ ->
        {:ok,
         socket
         |> assign(bookings: [], sidebar: :assignments, page_title: "Bookings")
         |> put_flash(:error, "Error loading bookings.")}
    end
  end

  def handle_params(_params, _url, socket) do
    case fetch_bookings(socket) do
      {:ok, bookings} ->
        {:noreply, assign(socket, bookings: bookings, sidebar: :assignments, page_title: "Bookings")}

      _ ->
        {:noreply,
         socket
         |> assign(bookings: [], sidebar: :assignments, page_title: "Bookings")
         |> put_flash(:error, "Error loading bookings.")}
    end
  end

  defp fetch_bookings(%{
         assigns: %{current_user_tenant: current_user_tenant, current_tenant: current_tenant}
       }) do
    case HousingApp.Assignments.Booking.list(actor: current_user_tenant, tenant: current_tenant) do
      {:ok, bookings} -> {:ok, bookings}
      _ -> {:error, []}
    end
  end
end
