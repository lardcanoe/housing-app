defmodule HousingAppWeb.Components.Drawer.Room do
  @moduledoc false

  use HousingAppWeb, :live_component

  import HousingAppWeb.CoreComponents, only: [icon: 1, json_view: 1]

  attr :id, :string, required: true
  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true

  def render(%{room: nil} = assigns) do
    ~H"""
    <div class="hidden" id={@id}></div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="text-gray-900 dark:text-white" id={@id}>
      <button
        type="button"
        phx-click={JS.add_class("hidden", to: "##{@id}-parent")}
        class="text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 top-2.5 right-2.5 inline-flex items-center dark:hover:bg-gray-600 dark:hover:text-white"
      >
        <.icon name="hero-x-mark-solid" class="w-5 h-5" />
        <span class="sr-only">Close menu</span>
      </button>

      <div class="flex items-center mb-4 sm:mb-5">
        <.icon name="hero-building-office-2-solid" class="w-12 h-12" />
        <div>
          <h4 id="drawer-label" class="mb-1 text-xl font-bold leading-none text-gray-900 dark:text-white">
            <%= @room.name %>
          </h4>
          <p class="text-base text-gray-500 dark:text-gray-400">
            <%= @room.building.name %>
          </p>
        </div>
      </div>
      <dl>
        <dt
          :if={@current_user_tenant.user.role == :platform_admin}
          class="mb-2 font-semibold leading-none text-gray-900 dark:text-white"
        >
          Id
        </dt>
        <dd
          :if={@current_user_tenant.user.role == :platform_admin}
          class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400"
        >
          <%= @room.id %>
        </dd>
        <dt class="mb-2 font-semibold leading-none text-gray-900 dark:text-white">Floor</dt>
        <dd class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400"><%= @room.floor %></dd>
        <dt :if={@room.block != ""} class="mb-2 font-semibold leading-none text-gray-900 dark:text-white">Block</dt>
        <dd :if={@room.block != ""} class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400"><%= @room.block %></dd>
        <dt class="mb-2 font-semibold leading-none text-gray-900 dark:text-white">Max Capacity</dt>
        <dd class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400"><%= @room.max_capacity %></dd>
        <dt class="mb-2 font-semibold leading-none text-gray-900 dark:text-white">Bookings</dt>
        <dd :if={@bookings == []} class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400">None</dd>
        <%= for booking <- @bookings do %>
          <dd class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400">
            <%= booking.profile.user_tenant.user.name %>, Bed: <%= booking.bed.name %>
          </dd>
        <% end %>
      </dl>

      <.json_view :if={@json_schema} data={@room.data} json_schema={@json_schema} />
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket |> assign(json_schema: nil, room: nil, bookings: [])}
  end

  def update(
        %{room_id: room_id},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    with {:ok, room} <-
           HousingApp.Assignments.Room.get_by_id(room_id, actor: current_user_tenant, tenant: tenant),
         bookings <-
           HousingApp.Assignments.Booking.list_by_room!(room.id, actor: current_user_tenant, tenant: tenant) do
      json_schema =
        case HousingApp.Management.get_room_form(actor: current_user_tenant, tenant: tenant) do
          {:ok, form} -> form.json_schema |> Jason.decode!()
          {:error, _} -> nil
        end

      {:ok, assign(socket, json_schema: json_schema, room: room, bookings: bookings)}
    else
      {:error, _} ->
        {:ok, assign(socket, room: nil, bookings: [])}
    end
  end

  def update(params, socket) do
    {:ok, assign(socket, params)}
  end
end
