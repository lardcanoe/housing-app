defmodule HousingAppWeb.Live.Assignments.Roommates.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Roommates"
      count={@count}
      loading={@loading}
      current_user_tenant={@current_user_tenant}
      current_tenant={@current_tenant}
    >
      <:actions>
        <.link patch={~p"/assignments/roommates/new"}>
          <button
            type="button"
            class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add roommate
          </button>
        </.link>
      </:actions>
    </.data_grid>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, loading: true, count: 0, sidebar: :assignments, page_title: "Roommates")}
  end

  def handle_params(params, _url, socket) do
    {:noreply,
     assign(socket,
       params: params,
       loading: true,
       count: 0,
       sidebar: :assignments,
       page_title: "Roommates"
     )}
  end

  def handle_event("view-row", %{"id" => _id}, socket) do
    # send_update(HousingAppWeb.Components.Drawer.Roommate, id: "drawer-right", roommate_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/assignments/roommates/#{id}/edit")}
  end

  def handle_event(
        "load-data",
        %{},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    roommates =
      [actor: current_user_tenant, tenant: tenant]
      |> HousingApp.Assignments.Roommate.list!()
      |> Enum.sort_by(& &1.roommate_group.name)
      |> Enum.map(fn p ->
        %{
          "id" => p.id,
          "name" => p.roommate_group.name,
          "user" => p.user_tenant.user.name,
          "actions" => [["Edit"], ["View"]]
        }
      end)

    columns =
      [
        %{
          field: "name",
          headerName: "Group Name",
          minWidth: 160,
          pinned: "left",
          checkboxSelection: true,
          headerCheckboxSelection: true
        },
        %{field: "id", minWidth: 120, pinned: "left", hide: true},
        %{field: "user"},
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
       data: roommates
     }, assign(socket, loading: false, count: length(roommates))}
  end
end
