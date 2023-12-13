defmodule HousingAppWeb.Components.DataGrid do
  @moduledoc false

  use Phoenix.Component
  use HousingAppWeb, :verified_routes

  import HousingAppWeb.CoreComponents,
    only: [
      icon: 1
    ]

  attr :id, :string, required: true
  attr :header, :string, required: true
  attr :loading, :boolean, required: true
  attr :count, :integer, required: true
  attr :drawer, :any, default: nil
  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string

  slot :actions, doc: "the slot for showing user actions in the last table column"

  def data_grid(assigns) do
    ~H"""
    <div class="flex">
      <div class="grow">
        <div class="relative overflow-hidden bg-white dark:bg-gray-900 sm:rounded-lg">
          <div class="flex flex-col md:flex-row items-center justify-between space-y-3 md:space-y-0 md:space-x-4 p-2">
            <div class="w-full flex items-center space-x-3">
              <h1 class="dark:text-white font-semibold"><%= @header %></h1>
              <div :if={@loading} class="text-gray-400 font-medium">Loading...</div>
              <div :if={!@loading && @count == 1} class="text-gray-400 font-medium">1 result</div>
              <div :if={!@loading && @count != 1} class="text-gray-400 font-medium"><%= @count %> results</div>
            </div>
            <div class="w-full flex flex-row items-center justify-end space-x-3">
              <div :for={action <- @actions} :if={@actions != []}>
                <%= render_slot(action) %>
              </div>

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
                    <li :if={@current_user_tenant.user.role == :platform_admin}>
                      <div class="flex items-center">
                        <input
                          id="table-settings-show-ids"
                          type="checkbox"
                          name="table-settings-show-ids"
                          class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-700 dark:focus:ring-offset-gray-700 focus:ring-2 dark:bg-gray-600 dark:border-gray-500"
                        />
                        <label
                          for="table-settings-show-ids"
                          class="ms-2 text-sm font-medium text-gray-900 dark:text-gray-300"
                        >
                          Show IDs
                        </label>
                      </div>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>

          <div class="dashboard-area-height mt-2">
            <div
              id={@id}
              style="width: 100%; height: 100%;"
              class="ag-theme-quartz-dark"
              aria-multiselectable="true"
              phx-hook="AgGrid"
            >
            </div>
          </div>
        </div>
      </div>

      <div
        :if={@drawer}
        class="hidden w-80 ml-4 pl-2 bg-white border-r border-gray-200 dark:bg-gray-800 dark:border-gray-700"
        id="drawer-right-parent"
      >
        <.live_component
          module={@drawer}
          id="drawer-right"
          current_user_tenant={@current_user_tenant}
          current_tenant={@current_tenant}
        >
        </.live_component>
      </div>
    </div>
    """
  end
end
