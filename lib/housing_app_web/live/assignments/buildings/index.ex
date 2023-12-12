defmodule HousingAppWeb.Live.Assignments.Buildings.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.data_grid id="ag-data-grid" header="Buildings" count={@count} loading={@loading}>
      <:actions>
        <.link patch={~p"/assignments/buildings/new"}>
          <button
            type="button"
            class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add building
          </button>
        </.link>
      </:actions>
    </.data_grid>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, loading: true, count: 0, sidebar: :assignments, page_title: "Buildings")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params, loading: true, count: 0, sidebar: :assignments, page_title: "Buildings")}
  end

  def handle_event(
        "load-data",
        %{},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    buildings =
      HousingApp.Assignments.Building.list!(actor: current_user_tenant, tenant: tenant)
      |> Enum.sort_by(& &1.name)
      |> Enum.map(fn p ->
        %{
          "id" => p.id,
          "name" => p.name,
          "location" => p.location,
          "floors" => p.floors,
          "rooms" => p.rooms,
          "actions" => [["Edit", ~p"/assignments/buildings/#{p.id}/edit"]]
        }
      end)

    columns =
      if current_user_tenant.user.role == :platform_admin do
        [
          %{field: "id", minWidth: 120, pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
          %{field: "name", minWidth: 160, pinned: "left"},
          %{field: "location"},
          %{field: "floors"},
          %{field: "rooms"},
          %{
            field: "actions",
            pinned: "right",
            maxWidth: 90,
            filter: false,
            editable: false,
            sortable: false,
            resizable: false
          }
        ]
      else
        [
          %{field: "name", minWidth: 160, pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
          %{field: "location"},
          %{field: "floors"},
          %{field: "rooms"},
          %{
            field: "actions",
            pinned: "right",
            maxWidth: 90,
            filter: false,
            editable: false,
            sortable: false,
            resizable: false
          }
        ]
      end

    {:reply,
     %{
       columns: columns,
       data: buildings
     }, assign(socket, loading: false, count: length(buildings))}
  end
end
