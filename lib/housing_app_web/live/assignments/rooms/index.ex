defmodule HousingAppWeb.Live.Assignments.Rooms.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingAppWeb.Components.DataGrid

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Rooms"
      count={@count}
      loading={@loading}
      drawer={HousingAppWeb.Components.Drawer.Room}
      current_user_tenant={@current_user_tenant}
      current_tenant={@current_tenant}
    >
      <:actions>
        <.common_query_filter queries={@queries} query_id={@query_id} />
      </:actions>
      <:actions>
        <.link navigate={~p"/assignments/rooms/new"}>
          <button
            type="button"
            class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add room
          </button>
        </.link>
      </:actions>
    </.data_grid>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(query_id: nil, loading: true, count: 0, sidebar: :assignments, page_title: "Rooms")
     |> load_async_assigns()}
  end

  defp load_async_assigns(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    assign_async(socket, [:queries], fn ->
      queries =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Management.CommonQuery.list!()
        |> Enum.filter(&(&1.resource == :room))

      {:ok, %{queries: [%{id: nil, name: "Default"}] ++ queries}}
    end)
  end

  def handle_event("view-row", %{"id" => id}, socket) do
    send_update(HousingAppWeb.Components.Drawer.Room, id: "drawer-right", room_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/assignments/rooms/#{id}/edit")}
  end

  def handle_event("change-query", params, socket) do
    {:noreply, HousingAppWeb.Components.FilteredResource.handle_change_query(socket, params)}
  end

  def handle_event("load-data", %{}, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    rooms =
      socket
      |> filter_rooms()
      |> Enum.sort_by(&{&1.building.name, &1.name})
      |> Enum.map(fn p ->
        %{
          "id" => p.id,
          "name" => p.name,
          "building" => p.building.name,
          "floor" => p.floor,
          "block" => p.block,
          "max_capacity" => p.max_capacity,
          "data" => p.data,
          "actions" => [["Edit"], ["View"]]
        }
      end)

    form_columns =
      case HousingApp.Management.Service.get_room_form(actor: current_user_tenant, tenant: tenant) do
        {:ok, form} ->
          form.json_schema
          |> Jason.decode!()
          |> HousingApp.Utils.JsonSchema.schema_to_aggrid_columns("data.")

        _ ->
          []
      end

    columns =
      [
        %{field: "name", pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
        %{field: "building", pinned: "left"},
        %{field: "id", pinned: "left", hide: true},
        %{field: "floor"},
        %{field: "block"},
        %{field: "max_capacity"}
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
       data: rooms
     }, assign(socket, loading: false, count: length(rooms))}
  end

  defp filter_rooms(%{assigns: %{query_id: nil}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns
    HousingApp.Assignments.Room.list!(actor: current_user_tenant, tenant: tenant)
  end

  defp filter_rooms(%{assigns: %{queries: %{ok?: false}}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns
    # TODO: Handle still loading?
    HousingApp.Assignments.Room.list!(actor: current_user_tenant, tenant: tenant)
  end

  defp filter_rooms(%{assigns: %{query_id: query_id, queries: %{ok?: true, result: queries}}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    query = Enum.find(queries, &(&1.id == query_id))

    if query do
      HousingApp.Assignments.Service.filter_resource(HousingApp.Assignments.Room, :list, query,
        actor: current_user_tenant,
        tenant: tenant
      )
    else
      # TODO: Not found
      HousingApp.Assignments.Room.list!(actor: current_user_tenant, tenant: tenant)
    end
  end
end
