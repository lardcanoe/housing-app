defmodule HousingAppWeb.Live.Assignments.Rooms.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Rooms"
      count={@count}
      loading={@loading}
      current_user_tenant={@current_user_tenant}
    >
      <:actions>
        <.link patch={~p"/assignments/rooms/new"}>
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
    {:ok, assign(socket, loading: true, count: 0, sidebar: :assignments, page_title: "Rooms")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params, loading: true, count: 0, sidebar: :assignments, page_title: "Rooms")}
  end

  def handle_event(
        "load-data",
        %{},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    rooms =
      HousingApp.Assignments.Room.list!(actor: current_user_tenant, tenant: tenant)
      |> Enum.sort_by(&{&1.building.name, &1.name})
      |> Enum.map(fn p ->
        %{
          "id" => p.id,
          "name" => p.name,
          "building" => p.building.name,
          "floor" => p.floor,
          "block" => p.block,
          "max_capacity" => p.max_capacity,
          "actions" => [["Edit", ~p"/assignments/rooms/#{p.id}/edit"]]
        }
      end)

    columns =
      [
        %{field: "name", pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
        %{field: "building", pinned: "left"},
        %{field: "id", pinned: "left", hide: true},
        %{field: "floor"},
        %{field: "block"},
        %{field: "max_capacity"},
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

    {:reply,
     %{
       columns: columns,
       data: rooms
     }, assign(socket, loading: false, count: length(rooms))}
  end
end
