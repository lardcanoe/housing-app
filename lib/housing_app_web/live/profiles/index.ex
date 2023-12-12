defmodule HousingAppWeb.Live.Profiles.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div class="relative overflow-hidden bg-white shadow-md dark:bg-gray-900 sm:rounded-lg">
      <div class="flex flex-col items-start justify-between p-2 space-y-3 dark:bg-gray-800 md:flex-row md:items-center md:space-y-0 md:space-x-4">
        <div class="flex items-center">
          <h1 class="mr-3 text-2xl font-bold dark:text-white">Profiles</h1>
        </div>
        <div class="flex flex-row items-center justify-end flex-shrink-0 w-auto space-x-3">
          <button
            type="button"
            class="flex items-center justify-center flex-shrink-0 px-4 py-2 text-sm font-medium text-white rounded-lg bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <.link patch={~p"/profiles/new"}>
              Add profile
            </.link>
          </button>
        </div>
      </div>
    </div>

    <div class="dashboard-area-height mt-2">
      <div id="myGrid" style="width: 100%; height: 100%;" class="ag-theme-quartz-dark" phx-hook="AgGrid"></div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, sidebar: :profiles, page_title: "Profiles")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
  end

  def handle_event(
        "load-data",
        %{},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    profiles =
      HousingApp.Management.Profile.list!(actor: current_user_tenant, tenant: tenant)
      |> Enum.sort_by(& &1.user_tenant.user.name)
      |> Enum.map(fn p ->
        if current_user_tenant.user.role == :platform_admin do
          %{
            "id" => p.id,
            "name" => p.user_tenant.user.name,
            "email" => p.user_tenant.user.email,
            "edit" => ~p"/profiles/#{p.id}/edit"
          }
        else
          %{
            "name" => p.user_tenant.user.name,
            "email" => p.user_tenant.user.email,
            "edit" => ~p"/profiles/#{p.id}/edit"
          }
        end
      end)

    if current_user_tenant.user.role == :platform_admin do
      {:reply,
       %{
         columns: [
           %{field: "id", minWidth: 120},
           %{field: "name", minWidth: 160},
           %{field: "email", email: true, minWidth: 160},
           %{field: "edit", link: "Edit", maxWidth: 90, filter: false, editable: false, sortable: false}
         ],
         data: profiles
       }, socket}
    else
      {:reply,
       %{
         columns: [
           %{field: "name", minWidth: 160},
           %{field: "email", email: true, minWidth: 160},
           %{field: "edit", link: "Edit", maxWidth: 90, filter: false, editable: false, sortable: false}
         ],
         data: profiles
       }, socket}
    end
  end
end
