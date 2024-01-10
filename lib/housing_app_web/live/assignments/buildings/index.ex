defmodule HousingAppWeb.Live.Assignments.Buildings.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingAppWeb.Components.DataGrid

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Buildings"
      count={@count}
      loading={@loading}
      drawer={HousingAppWeb.Components.Drawer.Building}
      current_user_tenant={@current_user_tenant}
      current_tenant={@current_tenant}
    >
      <:actions>
        <.link navigate={~p"/assignments/buildings/new"}>
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

  def handle_event("view-row", %{"id" => id}, socket) do
    send_update(HousingAppWeb.Components.Drawer.Building, id: "drawer-right", building_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/assignments/buildings/#{id}/edit")}
  end

  def handle_event("load-data", %{}, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    buildings =
      [actor: current_user_tenant, tenant: tenant]
      |> HousingApp.Assignments.Building.list!()
      |> Enum.sort_by(& &1.name)
      |> Enum.map(fn p ->
        %{
          "id" => p.id,
          "name" => p.name,
          "location" => p.location,
          "floors" => p.floor_count,
          "rooms" => p.room_count,
          "data" => p.data,
          "actions" => [["Edit"], ["View"]]
        }
      end)

    form_columns =
      case HousingApp.Management.Service.get_building_form(actor: current_user_tenant, tenant: tenant) do
        {:ok, form} ->
          form.json_schema
          |> Jason.decode!()
          |> HousingApp.Utils.JsonSchema.schema_to_aggrid_columns("data.")

        _ ->
          []
      end

    columns =
      [
        %{field: "name", minWidth: 160, pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
        %{field: "id", minWidth: 120, pinned: "left", hide: true},
        %{field: "location"},
        %{field: "floors"},
        %{field: "rooms"}
      ] ++
        form_columns ++
        [
          %{
            field: "actions",
            pinned: "right",
            minWidth: 120,
            maxWidth: 120,
            filter: false,
            editable: false,
            sortable: false,
            resizable: false
          }
        ]

    {:reply,
     %{
       columns: columns,
       data: buildings
     }, assign(socket, loading: false, count: length(buildings))}
  end
end
