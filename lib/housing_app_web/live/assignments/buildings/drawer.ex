defmodule HousingAppWeb.Components.Drawer.Building do
  @moduledoc false

  use HousingAppWeb, :live_component

  attr :id, :string, required: true
  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true

  def render(assigns) do
    ~H"""
    <div class={is_nil(@building) && "hidden"} id={@id}>
      <div :if={@building} class="flex items-center mb-4 sm:mb-5">
        <img
          class="w-12 h-12 rounded-full sm:mr-3"
          src="https://flowbite.s3.amazonaws.com/blocks/marketing-ui/avatars/helene-engels.png"
          alt="Helene avatar"
        />
        <div>
          <h4 id="drawer-label" class="mb-1 text-xl font-bold leading-none text-gray-900 dark:text-white">
            <%= @building.name %>
          </h4>
          <p class="text-gray-500 dark:text-gray-400">helene@example.com</p>
          <p class="text-gray-500 dark:text-gray-400"><%= @building.id %></p>
        </div>
        <button
          type="button"
          phx-click={JS.add_class("hidden", to: "##{@id}-parent")}
          class="text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 top-2.5 right-2.5 inline-flex items-center dark:hover:bg-gray-600 dark:hover:text-white"
        >
          <svg aria-hidden="true" class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
            <path
              fill-rule="evenodd"
              d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
              clip-rule="evenodd"
            >
            </path>
          </svg>
          <span class="sr-only">Close menu</span>
        </button>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket |> assign(building: nil)}
  end

  def update(
        %{building_id: building_id},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    case HousingApp.Assignments.Building.get_by_id(building_id, actor: current_user_tenant, tenant: tenant) do
      {:ok, building} ->
        {:ok, assign(socket, building: building)}

      {:error, _} ->
        {:ok, assign(socket, building: nil)}
    end
  end

  def update(params, socket) do
    {:ok, assign(socket, params)}
  end
end
