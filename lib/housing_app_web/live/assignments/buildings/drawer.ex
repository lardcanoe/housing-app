defmodule HousingAppWeb.Components.Drawer.Building do
  @moduledoc false

  use HousingAppWeb, :live_component

  import HousingAppWeb.CoreComponents, only: [icon: 1, json_view: 1]

  attr :id, :string, required: true
  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true

  def render(%{building: nil} = assigns) do
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
            <%= @building.name %>
          </h4>
          <p
            :if={!is_nil(@building.location) && @building.location != ""}
            class="text-base text-gray-500 dark:text-gray-400"
          >
            <%= @building.location %>
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
          <%= @building.id %>
        </dd>
        <dt class="mb-2 font-semibold leading-none text-gray-900 dark:text-white">Floors</dt>
        <dd class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400"><%= @building.floors %></dd>
        <dt class="mb-2 font-semibold leading-none text-gray-900 dark:text-white">Rooms</dt>
        <dd class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400"><%= @building.rooms %></dd>
      </dl>

      <.json_view :if={@json_schema} data={@building.data} json_schema={@json_schema} />
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, json_schema: nil, building: nil)}
  end

  def update(
        %{building_id: building_id},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    case HousingApp.Assignments.Building.get_by_id(building_id, actor: current_user_tenant, tenant: tenant) do
      {:ok, building} ->
        json_schema =
          case HousingApp.Management.get_building_form(actor: current_user_tenant, tenant: tenant) do
            {:ok, form} -> Jason.decode!(form.json_schema)
            {:error, _} -> nil
          end

        {:ok, assign(socket, json_schema: json_schema, building: building)}

      {:error, _} ->
        {:ok, assign(socket, building: nil, bookings: [])}
    end
  end

  def update(params, socket) do
    {:ok, assign(socket, params)}
  end
end
