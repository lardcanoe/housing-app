defmodule HousingAppWeb.Live.Assignments.Beds.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

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
        <.link patch={~p"/assignments/beds/new"}>
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
    {:ok, assign(socket, loading: true, count: 0, sidebar: :assignments, page_title: "Beds")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params, loading: true, count: 0, sidebar: :assignments, page_title: "Beds")}
  end

  def handle_event("view-row", %{"id" => id}, socket) do
    send_update(HousingAppWeb.Components.Drawer.Bed, id: "drawer-right", bed_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, socket |> push_navigate(to: ~p"/assignments/beds/#{id}/edit")}
  end

  def handle_event(
        "load-data",
        %{},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    beds =
      HousingApp.Assignments.Bed.list!(actor: current_user_tenant, tenant: tenant)
      |> Enum.sort_by(&{&1.room.building.name, &1.room.name, &1.name})
      |> Enum.map(fn p ->
        %{
          "id" => p.id,
          "name" => p.name,
          "building" => p.room.building.name,
          "room" => p.room.name,
          "floor" => p.room.floor,
          "actions" => [["Edit"], ["View"]]
        }
      end)

    columns =
      [
        %{field: "building", pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
        %{field: "room", pinned: "left"},
        %{field: "id", pinned: "left", hide: true},
        %{field: "name"},
        %{field: "floor"},
        %{
          field: "actions",
          pinned: "right",
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
       data: beds
     }, assign(socket, loading: false, count: length(beds))}
  end
end
