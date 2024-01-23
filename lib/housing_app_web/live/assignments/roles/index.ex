defmodule HousingAppWeb.Live.Assignments.Roles.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingAppWeb.Components.DataGrid

  def render(assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Roles"
      count={@count}
      loading={@loading}
      current_user_tenant={@current_user_tenant}
      current_tenant={@current_tenant}
    >
      <:actions>
        <.link :if={@live_action == :student_index} navigate={~p"/assignments/roles/new?for=student"}>
          <button
            type="button"
            class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add student assignment
          </button>
        </.link>
        <.link :if={@live_action == :staff_index} navigate={~p"/assignments/roles/new"}>
          <button
            type="button"
            class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add staff assignment
          </button>
        </.link>
      </:actions>
    </.data_grid>
    """
  end

  def mount(_params, _session, %{assigns: %{live_action: :student_index}} = socket) do
    {:ok, assign(socket, loading: true, count: 0, sidebar: :residents, page_title: "Student Staff")}
  end

  def mount(_params, _session, %{assigns: %{live_action: :staff_index}} = socket) do
    {:ok, assign(socket, loading: true, count: 0, sidebar: :setup, page_title: "Staff Assignments")}
  end

  def handle_event("view-row", %{"id" => _id}, socket) do
    # send_update(HousingAppWeb.Components.Drawer.Roommate, id: "drawer-right", roommate_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/assignments/roles/#{id}/edit")}
  end

  def handle_event("load-data", %{}, socket) do
    %{live_action: live_action, current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    read_action =
      case live_action do
        :student_index -> :list_student
        :staff_index -> :list_staff
      end

    role_queries =
      HousingApp.Assignments.RoleQuery
      |> Ash.Query.for_read(read_action, %{}, actor: current_user_tenant, tenant: tenant)
      |> HousingApp.Assignments.read!()
      |> Enum.sort_by(& &1.user_tenant_role.role.name)
      |> Enum.map(fn r ->
        %{
          "id" => r.id,
          "role_name" => r.user_tenant_role.role.name,
          "time_period" => if(r.user_tenant_role.time_period, do: r.user_tenant_role.time_period.name, else: ""),
          "user_name" => r.user_tenant_role.user_tenant.user.name,
          "common_query" => if(r.common_query, do: r.common_query.name, else: ""),
          "actions" => [["Edit"], ["View"]]
        }
      end)

    columns =
      [
        %{
          field: "role_name",
          headerName: "Role Name",
          minWidth: 160,
          pinned: "left",
          checkboxSelection: true,
          headerCheckboxSelection: true
        },
        %{field: "id", minWidth: 120, pinned: "left", hide: true},
        %{field: "time_period", headerName: "Time Period"},
        %{field: "user_name", headerName: "User"},
        %{field: "common_query", headerName: "Query"},
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
       data: role_queries
     }, assign(socket, loading: false, count: length(role_queries))}
  end
end
