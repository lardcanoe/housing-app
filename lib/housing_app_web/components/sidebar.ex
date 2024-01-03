defmodule HousingAppWeb.Components.Sidebar do
  @moduledoc false

  use Phoenix.Component
  use HousingAppWeb, :verified_routes

  import HousingAppWeb.CoreComponents, only: [icon: 1]

  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :any, required: true
  attr :section, :any, default: nil

  def sidebar(%{current_user_tenant: %{user_type: :user}} = assigns) do
    ~H"""
    <aside
      class="fixed top-0 left-0 z-40 w-64 h-screen pt-14 transition-transform -translate-x-full bg-white border-r border-gray-200 md:translate-x-0 dark:bg-gray-800 dark:border-gray-700"
      aria-label="Sidenav"
      id="drawer-navigation"
    >
      <div class="overflow-y-auto py-5 px-3 h-full bg-white dark:bg-gray-800">
        <ul class="space-y-2">
          <li>
            <.link
              patch={~p"/"}
              class="flex items-center p-2 text-base font-medium text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 group"
            >
              <svg
                aria-hidden="true"
                class="w-6 h-6 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path d="M2 10a8 8 0 018-8v8h8a8 8 0 11-16 0z"></path>
                <path d="M12 2.252A8.014 8.014 0 0117.748 8H12V2.252z"></path>
              </svg>
              <span class="ml-3">Overview</span>
            </.link>
          </li>
          <li>
            <.link
              patch={~p"/applications"}
              class="flex items-center p-2 text-base font-medium text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 group"
            >
              <svg
                aria-hidden="true"
                class="w-6 h-6 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path d="M2 10a8 8 0 018-8v8h8a8 8 0 11-16 0z"></path>
                <path d="M12 2.252A8.014 8.014 0 0117.748 8H12V2.252z"></path>
              </svg>
              <span class="ml-3">My Applications</span>
            </.link>
          </li>
          <li>
            <.link
              patch={~p"/roommates"}
              class="flex items-center p-2 text-base font-medium text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 group"
            >
              <svg
                aria-hidden="true"
                class="w-6 h-6 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path d="M2 10a8 8 0 018-8v8h8a8 8 0 11-16 0z"></path>
                <path d="M12 2.252A8.014 8.014 0 0117.748 8H12V2.252z"></path>
              </svg>
              <span class="ml-3">My Roommates</span>
            </.link>
          </li>
          <li>
            <.link
              patch={~p"/"}
              class="flex items-center p-2 text-base font-medium text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 group"
            >
              <svg
                aria-hidden="true"
                class="w-6 h-6 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path d="M2 10a8 8 0 018-8v8h8a8 8 0 11-16 0z"></path>
                <path d="M12 2.252A8.014 8.014 0 0117.748 8H12V2.252z"></path>
              </svg>
              <span class="ml-3">Housing</span>
            </.link>
          </li>
        </ul>
      </div>
    </aside>
    """
  end

  def sidebar(assigns) do
    assigns =
      assign_new(assigns, :form_types, fn ->
        {:ok, form_types} =
          HousingApp.Management.Form.get_types(
            actor: assigns.current_user_tenant,
            tenant: assigns.current_tenant
          )

        form_types
      end)

    assigns =
      assign_new(assigns, :application_types, fn ->
        {:ok, application_types} =
          HousingApp.Management.Application.get_types(
            actor: assigns.current_user_tenant,
            tenant: assigns.current_tenant
          )

        application_types
      end)

    ~H"""
    <aside
      class="fixed top-0 left-0 z-40 w-64 h-screen pt-14 transition-transform -translate-x-full bg-white border-r border-gray-200 md:translate-x-0 dark:bg-gray-800 dark:border-gray-700"
      aria-label="Sidenav"
      id="drawer-navigation"
    >
      <div class="overflow-y-auto py-5 px-3 h-full bg-white dark:bg-gray-800">
        <form action="#" method="GET" class="md:hidden mb-2">
          <label for="sidebar-search" class="sr-only">Search</label>
          <div class="relative">
            <div class="flex absolute inset-y-0 left-0 items-center pl-3 pointer-events-none">
              <svg
                class="w-5 h-5 text-gray-500 dark:text-gray-400"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  fill-rule="evenodd"
                  clip-rule="evenodd"
                  d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z"
                >
                </path>
              </svg>
            </div>
            <input
              type="text"
              name="search"
              id="sidebar-search"
              class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-primary-500 focus:border-primary-500 block w-full pl-10 p-2 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-primary-500 dark:focus:border-primary-500"
              placeholder="Search"
            />
          </div>
        </form>
        <ul class="space-y-2">
          <!-- Overview -->
          <li>
            <.link
              patch={~p"/"}
              class="flex items-center p-2 text-base font-medium text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 group"
            >
              <svg
                aria-hidden="true"
                class="w-6 h-6 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path d="M2 10a8 8 0 018-8v8h8a8 8 0 11-16 0z"></path>
                <path d="M12 2.252A8.014 8.014 0 0117.748 8H12V2.252z"></path>
              </svg>
              <span class="ml-3">Overview</span>
            </.link>
          </li>
          <!-- Forms -->
          <li>
            <button
              type="button"
              class="flex items-center p-2 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
              aria-controls="dropdown-forms"
              data-collapse-toggle="dropdown-forms"
            >
              <.icon
                name="hero-rectangle-group-solid"
                class="flex-shrink-0 w-6 h-6 text-gray-500 transition duration-75 group-hover:text-gray-900 dark:text-gray-400 dark:group-hover:text-white"
              />
              <span class="flex-1 ml-3 text-left whitespace-nowrap">Forms</span>
              <.svg_dropdown />
            </button>
            <ul id="dropdown-forms" class={["py-2 space-y-2", @section != :forms && "hidden"]}>
              <li>
                <.link
                  patch={~p"/forms"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  Manage
                </.link>
              </li>
              <li :for={t <- @form_types}>
                <.link
                  patch={~p"/forms?type=#{t}"}
                  class="flex items-center p-2 pl-11 w-full text-sm font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  <%= t %>
                </.link>
              </li>
            </ul>
          </li>
          <!-- Applications -->
          <li>
            <button
              type="button"
              class="flex items-center p-2 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
              aria-controls="dropdown-applications"
              data-collapse-toggle="dropdown-applications"
            >
              <.icon
                name="hero-document-text-solid"
                class="flex-shrink-0 w-6 h-6 text-gray-500 transition duration-75 group-hover:text-gray-900 dark:text-gray-400 dark:group-hover:text-white"
              />
              <span class="flex-1 ml-3 text-left whitespace-nowrap">Applications</span>
              <.svg_dropdown />
            </button>
            <ul id="dropdown-applications" class={["py-2 space-y-2", @section != :applications && "hidden"]}>
              <li>
                <.link
                  patch={~p"/applications"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  Manage
                </.link>
              </li>
              <li :for={t <- @application_types}>
                <.link
                  patch={~p"/applications?type=#{t}"}
                  class="flex items-center p-2 pl-11 w-full text-sm font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  <%= t %>
                </.link>
              </li>
            </ul>
          </li>
          <!-- Assignments -->
          <li>
            <button
              type="button"
              class="flex items-center p-2 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
              aria-controls="dropdown-assignments"
              data-collapse-toggle="dropdown-assignments"
            >
              <.icon
                name="hero-building-office-2-solid"
                class="flex-shrink-0 w-6 h-6 text-gray-500 transition duration-75 group-hover:text-gray-900 dark:text-gray-400 dark:group-hover:text-white"
              />
              <span class="flex-1 ml-3 text-left whitespace-nowrap">Assignments</span>
              <.svg_dropdown />
            </button>
            <ul id="dropdown-assignments" class={["py-2 space-y-2", @section != :assignments && "hidden"]}>
              <li>
                <.link
                  patch={~p"/assignments/buildings"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  Buildings
                </.link>
              </li>
              <li>
                <.link
                  patch={~p"/assignments/rooms"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  Rooms
                </.link>
              </li>
              <li>
                <.link
                  patch={~p"/assignments/beds"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  Beds
                </.link>
              </li>
              <li>
                <.link
                  patch={~p"/assignments/bookings"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  Bookings
                </.link>
              </li>
              <li>
                <.link
                  patch={~p"/assignments/roommates"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  Roommates
                </.link>
              </li>
            </ul>
          </li>
          <!-- Students -->
          <li>
            <button
              type="button"
              class="flex items-center p-2 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
              aria-controls="dropdown-profiles"
              data-collapse-toggle="dropdown-profiles"
            >
              <.icon
                name="hero-users-solid"
                class="flex-shrink-0 w-6 h-6 text-gray-500 transition duration-75 group-hover:text-gray-900 dark:text-gray-400 dark:group-hover:text-white"
              />
              <span class="flex-1 ml-3 text-left whitespace-nowrap">Students</span>
              <.svg_dropdown />
            </button>
            <ul id="dropdown-profiles" class={["py-2 space-y-2", @section != :profiles && "hidden"]}>
              <li>
                <.link
                  patch={~p"/profiles"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  Manage
                </.link>
              </li>
            </ul>
          </li>
          <!-- Accounting -->
          <li>
            <button
              type="button"
              class="flex items-center p-2 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
              aria-controls="dropdown-accounting"
              data-collapse-toggle="dropdown-accounting"
            >
              <.icon
                name="hero-currency-dollar-solid"
                class="flex-shrink-0 w-6 h-6 text-gray-500 transition duration-75 group-hover:text-gray-900 dark:text-gray-400 dark:group-hover:text-white"
              />
              <span class="flex-1 ml-3 text-left whitespace-nowrap">Accounting</span>
              <.svg_dropdown />
            </button>
            <ul id="dropdown-accounting" class={["py-2 space-y-2", @section != :accounting && "hidden"]}>
              <li>
                <.link
                  patch={~p"/accounting/products"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  Products
                </.link>
              </li>
            </ul>
          </li>
          <!-- Reporting -->
          <li>
            <button
              type="button"
              class="flex items-center p-2 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
              aria-controls="dropdown-reporting"
              data-collapse-toggle="dropdown-reporting"
            >
              <.icon
                name="hero-chart-bar-square-solid"
                class="flex-shrink-0 w-6 h-6 text-gray-500 transition duration-75 group-hover:text-gray-900 dark:text-gray-400 dark:group-hover:text-white"
              />
              <span class="flex-1 ml-3 text-left whitespace-nowrap">Reporting</span>
              <.svg_dropdown />
            </button>
            <ul id="dropdown-reporting" class={["py-2 space-y-2", @section != :reporting && "hidden"]}>
              <li>
                <.link
                  patch={~p"/reporting"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  View
                </.link>
              </li>
            </ul>
          </li>
        </ul>
        <ul class="pt-5 mt-5 space-y-2 border-t border-gray-200 dark:border-gray-700">
          <!-- New -->
          <li>
            <button
              type="button"
              class="flex items-center p-2 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
              aria-controls="dropdown-new"
              data-collapse-toggle="dropdown-new"
            >
              <.icon
                name="hero-plus-solid"
                class="flex-shrink-0 w-6 h-6 text-gray-500 transition duration-75 group-hover:text-gray-900 dark:text-gray-400 dark:group-hover:text-white"
              />
              <span class="flex-1 ml-3 text-left whitespace-nowrap">New</span>
              <.svg_dropdown />
            </button>
            <ul id="dropdown-new" class="hidden py-2 space-y-2">
              <li>
                <.link
                  patch={~p"/forms/new"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  New Form
                </.link>
              </li>
              <li>
                <.link
                  patch={~p"/applications/new"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  New Application
                </.link>
              </li>
              <li>
                <.link
                  patch={~p"/profiles/new"}
                  class="flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700"
                >
                  New Profile
                </.link>
              </li>
            </ul>
          </li>

          <li>
            <.link
              patch={~p"/"}
              class="flex items-center p-2 text-base font-medium text-gray-900 rounded-lg transition duration-75 hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-white group"
            >
              <svg
                aria-hidden="true"
                class="flex-shrink-0 w-6 h-6 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z"></path>
                <path
                  fill-rule="evenodd"
                  d="M4 5a2 2 0 012-2 3 3 0 003 3h2a3 3 0 003-3 2 2 0 012 2v11a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 4a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3zm-3 4a1 1 0 100 2h.01a1 1 0 100-2H7zm3 0a1 1 0 100 2h3a1 1 0 100-2h-3z"
                  clip-rule="evenodd"
                >
                </path>
              </svg>
              <span class="ml-3">Docs</span>
            </.link>
          </li>
          <li>
            <.link
              patch={~p"/"}
              class="flex items-center p-2 text-base font-medium text-gray-900 rounded-lg transition duration-75 hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-white group"
            >
              <svg
                aria-hidden="true"
                class="flex-shrink-0 w-6 h-6 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path d="M7 3a1 1 0 000 2h6a1 1 0 100-2H7zM4 7a1 1 0 011-1h10a1 1 0 110 2H5a1 1 0 01-1-1zM2 11a2 2 0 012-2h12a2 2 0 012 2v4a2 2 0 01-2 2H4a2 2 0 01-2-2v-4z">
                </path>
              </svg>
              <span class="ml-3">Components</span>
            </.link>
          </li>
          <li>
            <.link
              patch={~p"/"}
              class="flex items-center p-2 text-base font-medium text-gray-900 rounded-lg transition duration-75 hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-white group"
            >
              <svg
                aria-hidden="true"
                class="flex-shrink-0 w-6 h-6 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  fill-rule="evenodd"
                  d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-2 0c0 .993-.241 1.929-.668 2.754l-1.524-1.525a3.997 3.997 0 00.078-2.183l1.562-1.562C15.802 8.249 16 9.1 16 10zm-5.165 3.913l1.58 1.58A5.98 5.98 0 0110 16a5.976 5.976 0 01-2.516-.552l1.562-1.562a4.006 4.006 0 001.789.027zm-4.677-2.796a4.002 4.002 0 01-.041-2.08l-.08.08-1.53-1.533A5.98 5.98 0 004 10c0 .954.223 1.856.619 2.657l1.54-1.54zm1.088-6.45A5.974 5.974 0 0110 4c.954 0 1.856.223 2.657.619l-1.54 1.54a4.002 4.002 0 00-2.346.033L7.246 4.668zM12 10a2 2 0 11-4 0 2 2 0 014 0z"
                  clip-rule="evenodd"
                >
                </path>
              </svg>
              <span class="ml-3">Help</span>
            </.link>
          </li>
        </ul>
      </div>
    </aside>
    """
  end

  defp svg_dropdown(assigns) do
    ~H"""
    <svg aria-hidden="true" class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
      <path
        fill-rule="evenodd"
        d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
        clip-rule="evenodd"
      >
      </path>
    </svg>
    """
  end
end
