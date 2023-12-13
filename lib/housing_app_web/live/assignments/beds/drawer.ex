defmodule HousingAppWeb.Components.Drawer.Bed do
  @moduledoc false

  use HousingAppWeb, :live_component

  import HousingAppWeb.CoreComponents, only: [icon: 1]

  attr :id, :string, required: true
  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true

  def render(%{bed: nil} = assigns) do
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
            <%= @bed.name %>
          </h4>
          <p class="text-base text-gray-500 dark:text-gray-400">
            <%= @bed.room.building.name %>, <%= @bed.room.name %>
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
          <%= @bed.id %>
        </dd>
        <dt class="mb-2 font-semibold leading-none text-gray-900 dark:text-white">Floor</dt>
        <dd class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400"><%= @bed.room.floor %></dd>
        <dt :if={@bed.room.block != ""} class="mb-2 font-semibold leading-none text-gray-900 dark:text-white">Block</dt>
        <dd :if={@bed.room.block != ""} class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400">
          <%= @bed.room.block %>
        </dd>
        <dt class="mb-2 font-semibold leading-none text-gray-900 dark:text-white">Bookings</dt>
        <dd :if={@bookings == []} class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400">None</dd>
        <%= for booking <- @bookings do %>
          <dd class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400">
            <%= booking.profile.user_tenant.user.name %>
          </dd>
        <% end %>
      </dl>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket |> assign(bed: nil, bookings: [])}
  end

  def update(
        %{bed_id: bed_id},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    case HousingApp.Assignments.Bed.get_by_id(bed_id, actor: current_user_tenant, tenant: tenant) do
      {:ok, bed} ->
        bookings = HousingApp.Assignments.Booking.list_by_bed!(bed.id, actor: current_user_tenant, tenant: tenant)
        {:ok, assign(socket, bed: bed, bookings: bookings)}

      {:error, _} ->
        {:ok, assign(socket, bed: nil, bookings: [])}
    end
  end

  def update(params, socket) do
    {:ok, assign(socket, params)}
  end
end
