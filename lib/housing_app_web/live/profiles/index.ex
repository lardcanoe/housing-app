defmodule HousingAppWeb.Live.Profiles.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div class="relative overflow-hidden bg-white dark:bg-gray-900 sm:rounded-lg">
      <div class="flex flex-col md:flex-row items-center justify-between space-y-3 md:space-y-0 md:space-x-4 p-2">
        <div class="w-full flex items-center space-x-3">
          <h1 class="dark:text-white font-semibold">Profiles</h1>
          <div :if={@loading} class="text-gray-400 font-medium">Loading...</div>
          <div :if={!@loading} class="text-gray-400 font-medium"><%= @count %> results</div>
        </div>
        <div class="w-full flex flex-row items-center justify-end space-x-3">
          <.link patch={~p"/profiles/new"}>
            <button
              type="button"
              class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
            >
              <svg
                class="h-3.5 w-3.5 mr-2"
                fill="currentColor"
                viewbox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
              >
                <path
                  clip-rule="evenodd"
                  fill-rule="evenodd"
                  d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
                />
              </svg>
              Add profile
            </button>
          </.link>

          <div class="relative">
            <button
              type="button"
              id="dropdownTableSettings"
              data-dropdown-toggle="dropdownTableSettingsMenu"
              class="w-full md:w-auto flex items-center justify-center py-2 px-3 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-primary-700 focus:z-10 focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700"
            >
              <.icon name="hero-cog-6-tooth-solid" class="w-4 h-4 mr-2" /> Table settings
            </button>
            <!-- Dropdown menu -->
            <div
              id="dropdownTableSettingsMenu"
              class="hidden z-10 absolute list-none -translate-x-1/2 top-10 -left-32 w-48 bg-white divide-y divide-gray-100 rounded-lg dark:bg-gray-700 dark:divide-gray-600"
            >
              <ul class="p-3 space-y-3 text-sm text-gray-700 dark:text-gray-200" aria-labelledby="dropdownTableSettings">
                <li>
                  <div class="flex items-center">
                    <input
                      checked
                      id="table-settings-size-1"
                      type="radio"
                      value="normal"
                      name="table-settings-size"
                      class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-700 dark:focus:ring-offset-gray-700 focus:ring-2 dark:bg-gray-600 dark:border-gray-500"
                    />
                    <label for="table-settings-size-1" class="ms-2 text-sm font-medium text-gray-900 dark:text-gray-300">
                      Default size
                    </label>
                  </div>
                </li>
                <li>
                  <div class="flex items-center">
                    <input
                      id="table-settings-size-2"
                      type="radio"
                      value="compact"
                      name="table-settings-size"
                      class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-700 dark:focus:ring-offset-gray-700 focus:ring-2 dark:bg-gray-600 dark:border-gray-500"
                    />
                    <label for="table-settings-size-2" class="ms-2 text-sm font-medium text-gray-900 dark:text-gray-300">
                      Compact
                    </label>
                  </div>
                </li>
                <li>
                  <div class="flex items-center">
                    <input
                      id="table-settings-size-3"
                      type="radio"
                      value="large"
                      name="table-settings-size"
                      class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-700 dark:focus:ring-offset-gray-700 focus:ring-2 dark:bg-gray-600 dark:border-gray-500"
                    />
                    <label for="table-settings-size-3" class="ms-2 text-sm font-medium text-gray-900 dark:text-gray-300">
                      Large
                    </label>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <div class="dashboard-area-height mt-2">
        <div id="myGrid" style="width: 100%; height: 100%;" class="ag-theme-quartz-dark" phx-hook="AgGrid"></div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, loading: true, count: 0, sidebar: :profiles, page_title: "Profiles")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params, loading: true, count: 0, sidebar: :profiles, page_title: "Profiles")}
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
            "actions" => [["Edit", ~p"/profiles/#{p.id}/edit"]]
          }
        else
          %{
            "name" => p.user_tenant.user.name,
            "email" => p.user_tenant.user.email,
            "actions" => [["Edit", ~p"/profiles/#{p.id}/edit"]]
          }
        end
      end)

    if current_user_tenant.user.role == :platform_admin do
      {:reply,
       %{
         columns: [
           %{field: "id", minWidth: 120, pinned: "left", checkboxSelection: true},
           %{field: "name", minWidth: 160, pinned: "left"},
           %{field: "email", minWidth: 160},
           %{
             field: "actions",
             pinned: "right",
             maxWidth: 90,
             filter: false,
             editable: false,
             sortable: false,
             resizable: false
           }
         ],
         data: profiles
       }, assign(socket, loading: false, count: length(profiles))}
    else
      {:reply,
       %{
         columns: [
           %{field: "name", minWidth: 160, pinned: "left", checkboxSelection: true},
           %{field: "email", minWidth: 160},
           %{
             field: "actions",
             pinned: "right",
             maxWidth: 90,
             filter: false,
             editable: false,
             sortable: false,
             resizable: false
           }
         ],
         data: profiles
       }, assign(socket, loading: false, count: length(profiles))}
    end
  end
end
