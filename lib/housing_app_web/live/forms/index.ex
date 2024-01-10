defmodule HousingAppWeb.Live.Forms.Index do
  @moduledoc false
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingAppWeb.Components.DataGrid

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Forms"
      count={@count}
      loading={@loading}
      drawer={HousingAppWeb.Components.Drawer.Form}
      current_user_tenant={@current_user_tenant}
      current_tenant={@current_tenant}
    >
      <:actions>
        <.link navigate={~p"/forms/new"}>
          <button
            type="button"
            class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add form
          </button>
        </.link>
      </:actions>
    </.data_grid>
    """
  end

  # Need for "link patch" to work
  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params, loading: true, count: 0, sidebar: :forms, page_title: "Forms")}
  end

  def handle_event("view-row", %{"id" => id}, socket) do
    send_update(HousingAppWeb.Components.Drawer.Form, id: "drawer-right", form_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/forms/#{id}/edit")}
  end

  def handle_event("redirect", %{"url" => url}, socket) do
    {:noreply, push_navigate(socket, to: url)}
  end

  def handle_event("load-data", %{}, socket) do
    forms =
      socket
      |> fetch_forms()
      |> Enum.sort_by(& &1.name)
      |> map_forms()

    columns =
      [
        %{field: "name", minWidth: 200, pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
        %{field: "id", minWidth: 120, pinned: "left", hide: true},
        %{field: "status", maxWidth: 140, cellRenderer: "draftStatus"},
        %{field: "type"},
        %{field: "submissions", headerName: "Submissions", cellRenderer: "link"},
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
       data: forms
     }, assign(socket, loading: false, count: length(forms))}
  end

  defp fetch_forms(%{assigns: %{params: %{"type" => app_type}}} = socket) when is_binary(app_type) and app_type != "" do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns
    HousingApp.Management.Form.list_by_type!(app_type, actor: current_user_tenant, tenant: tenant)
  end

  defp fetch_forms(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns
    HousingApp.Management.Form.list!(actor: current_user_tenant, tenant: tenant)
  end

  defp map_forms(forms) do
    Enum.map(forms, fn b ->
      %{
        "id" => b.id,
        "name" => b.name,
        "status" => b.status,
        "type" => b.type,
        "submissions" => b.count_of_submissions,
        "submissions_link" => ~p"/forms/#{b.id}/submissions",
        "actions" => [["Edit"], ["View"]]
      }
    end)
  end
end
