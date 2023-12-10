defmodule HousingAppWeb.Live.Assignments.Beds.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Beds</h1>

    <.table id="beds" rows={@beds} pagination={false} row_id={fn row -> "beds-row-#{row.id}" end}>
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
        <.link patch={~p"/assignments/beds/new"}>
          Add bed
        </.link>
      </:button>
      <:col :let={bed} :if={@current_user.role == :platform_admin} label="id">
        <%= bed.id %>
      </:col>
      <:col :let={bed} label="building">
        <%= bed.room.building.name %>
      </:col>
      <:col :let={bed} label="room">
        <%= bed.room.name %>
      </:col>
      <:col :let={bed} label="name">
        <.link patch={~p"/assignments/beds/#{bed.id}"}><%= bed.name %></.link>
      </:col>
      <:col :let={bed} label="floor">
        <%= bed.room.floor %>
      </:col>
      <:col :let={bed} label="block">
        <%= bed.room.block %>
      </:col>
      <:action :let={bed}>
        <.link
          patch={~p"/assignments/beds/#{bed.id}/edit"}
          class="block py-2 px-4 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
        >
          Edit
        </.link>
      </:action>
    </.table>
    """
  end

  def mount(_params, _session, socket) do
    case fetch_beds(socket) do
      {:ok, beds} ->
        {:ok, assign(socket, beds: beds, sidebar: :assignments, page_title: "Beds")}

      _ ->
        {:ok,
         socket
         |> assign(beds: [], sidebar: :assignments, page_title: "Beds")
         |> put_flash(:error, "Error loading beds.")}
    end
  end

  def handle_params(_params, _url, socket) do
    case fetch_beds(socket) do
      {:ok, beds} ->
        {:noreply, assign(socket, beds: beds, sidebar: :assignments, page_title: "Beds")}

      _ ->
        {:noreply,
         socket
         |> assign(beds: [], sidebar: :assignments, page_title: "Beds")
         |> put_flash(:error, "Error loading beds.")}
    end
  end

  defp fetch_beds(%{
         assigns: %{current_user_tenant: current_user_tenant, current_tenant: current_tenant}
       }) do
    case HousingApp.Assignments.Bed.list(actor: current_user_tenant, tenant: current_tenant) do
      {:ok, beds} -> {:ok, beds}
      _ -> {:error, []}
    end
  end
end
