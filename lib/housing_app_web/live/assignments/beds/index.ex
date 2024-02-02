defmodule HousingAppWeb.Live.Assignments.Beds.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingAppWeb.Components.DataGrid

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Beds"
      count={@count}
      loading={@loading}
      drawer={HousingAppWeb.Components.Drawer.Bed}
      current_user_tenant={@current_user_tenant}
      current_tenant={@current_tenant}
    >
      <:actions>
        <.common_query_filter queries={@queries} query_id={@query_id} />
      </:actions>
      <:actions>
        <.link navigate={~p"/assignments/beds/new"}>
          <button
            type="button"
            class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add bed
          </button>
        </.link>
      </:actions>
    </.data_grid>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(query_id: nil, loading: true, count: 0, sidebar: :assignments, page_title: "Beds")
     |> load_async_assigns()}
  end

  defp load_async_assigns(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    assign_async(socket, [:queries], fn ->
      queries =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Management.CommonQuery.list!()
        |> Enum.filter(&(&1.resource in [:bed, :room, :building]))
        |> Enum.sort_by(&{&1.resource, &1.name})

      {:ok, %{queries: [%{id: nil, name: "Default"}] ++ queries}}
    end)
  end

  def handle_event("view-row", %{"id" => id}, socket) do
    send_update(HousingAppWeb.Components.Drawer.Bed, id: "drawer-right", bed_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/assignments/beds/#{id}/edit")}
  end

  def handle_event("change-query", params, socket) do
    {:noreply, HousingAppWeb.Components.FilteredResource.handle_change_query(socket, params)}
  end

  def handle_event("load-data", %{}, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    beds =
      socket
      |> filter_beds()
      |> Enum.sort_by(&{&1.room.building.name, &1.room.name, &1.name})
      |> Enum.map(fn p ->
        %{
          "id" => p.id,
          "name" => p.name,
          "building" => p.room.building.name,
          "room" => p.room.name,
          "floor" => p.room.floor,
          "data" => p.data,
          "actions" => [["Edit"], ["View"]]
        }
      end)

    form_columns =
      case HousingApp.Management.Service.get_bed_form(actor: current_user_tenant, tenant: tenant) do
        {:ok, form} ->
          form.json_schema
          |> Jason.decode!()
          |> HousingApp.Utils.JsonSchema.schema_to_aggrid_columns("data.")

        _ ->
          []
      end

    columns =
      [
        %{field: "building", pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
        %{field: "room", pinned: "left"},
        %{field: "id", pinned: "left", hide: true},
        %{field: "name"},
        %{field: "floor"}
      ] ++
        form_columns ++
        [
          %{
            field: "actions",
            pinned: "right",
            maxWidth: 120,
            minWidth: 120,
            filter: false,
            editable: false,
            sortable: false,
            resizable: false
          }
        ]

    {:reply,
     %{
       columns: columns,
       data: beds
     }, assign(socket, loading: false, count: length(beds))}
  end

  defp filter_beds(%{assigns: %{query_id: nil}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns
    HousingApp.Assignments.Bed.list!(actor: current_user_tenant, tenant: tenant)
  end

  defp filter_beds(%{assigns: %{queries: %{ok?: false}}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns
    # TODO: Handle still loading?
    HousingApp.Assignments.Bed.list!(actor: current_user_tenant, tenant: tenant)
  end

  defp filter_beds(%{assigns: %{query_id: query_id, queries: %{ok?: true, result: queries}}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    query = Enum.find(queries, &(&1.id == query_id))

    if query do
      HousingApp.Assignments.Service.filter_resource(HousingApp.Assignments.Bed, :list, query,
        actor: current_user_tenant,
        tenant: tenant
      )
    else
      # TODO: Not found
      HousingApp.Assignments.Bed.list!(actor: current_user_tenant, tenant: tenant)
    end
  end
end
