defmodule HousingAppWeb.Live.Settings.TenantSettings do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  on_mount HousingAppWeb.LiveLocale

  # https://flowbite.com/blocks/application/crud-update-forms/#update-user-form
  def render(%{live_action: :index} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Account Settings</h1>
    <div class="md:flex">
      <ul
        id="default-tab"
        data-tabs-toggle="#default-tab-content"
        role="tablist"
        class="flex-column md:w-52 space-y space-y-4 text-sm font-medium text-gray-500 dark:text-gray-400 md:me-4 mb-4 md:mb-0"
      >
        <li role="presentation">
          <a
            href="#"
            class="inline-flex items-center px-4 py-3 rounded-lg hover:text-gray-900 bg-gray-50 hover:bg-gray-100 w-full dark:bg-gray-800 dark:hover:bg-gray-700 dark:hover:text-white"
            aria-current="page"
            id="forms-tab"
            data-tabs-target="#forms"
            type="button"
            role="tab"
            aria-controls="forms"
            aria-selected="true"
          >
            <.icon name="hero-document-text-solid" class="w-4 h-4 me-2 text-white" /> Forms
          </a>
        </li>
        <li role="presentation">
          <a
            href="#"
            class="inline-flex items-center px-4 py-3 rounded-lg hover:text-gray-900 bg-gray-50 hover:bg-gray-100 w-full dark:bg-gray-800 dark:hover:bg-gray-700 dark:hover:text-white"
            aria-current="page"
            id="users-tab"
            data-tabs-target="#users"
            type="button"
            role="tab"
            aria-controls="users"
            aria-selected="true"
          >
            <.icon name="hero-user-solid" class="w-4 h-4 me-2 text-white" /> Users
          </a>
        </li>
        <li role="presentation">
          <a
            href="#"
            class="inline-flex items-center px-4 py-3 rounded-lg hover:text-gray-900 bg-gray-50 hover:bg-gray-100 w-full dark:bg-gray-800 dark:hover:bg-gray-700 dark:hover:text-white"
            id="time-periods-tab"
            data-tabs-target="#time-periods"
            type="button"
            role="tab"
            aria-controls="time-periods"
            aria-selected="false"
          >
            <svg
              class="w-4 h-4 me-2 text-gray-500 dark:text-gray-400"
              aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg"
              fill="currentColor"
              viewBox="0 0 18 18"
            >
              <path d="M6.143 0H1.857A1.857 1.857 0 0 0 0 1.857v4.286C0 7.169.831 8 1.857 8h4.286A1.857 1.857 0 0 0 8 6.143V1.857A1.857 1.857 0 0 0 6.143 0Zm10 0h-4.286A1.857 1.857 0 0 0 10 1.857v4.286C10 7.169 10.831 8 11.857 8h4.286A1.857 1.857 0 0 0 18 6.143V1.857A1.857 1.857 0 0 0 16.143 0Zm-10 10H1.857A1.857 1.857 0 0 0 0 11.857v4.286C0 17.169.831 18 1.857 18h4.286A1.857 1.857 0 0 0 8 16.143v-4.286A1.857 1.857 0 0 0 6.143 10Zm10 0h-4.286A1.857 1.857 0 0 0 10 11.857v4.286c0 1.026.831 1.857 1.857 1.857h4.286A1.857 1.857 0 0 0 18 16.143v-4.286A1.857 1.857 0 0 0 16.143 10Z" />
            </svg>
            Time Periods
          </a>
        </li>
      </ul>
      <div id="default-tab-content" class="w-full">
        <div
          class="hidden p-4 rounded-lg bg-gray-50 dark:bg-gray-800"
          id="forms"
          role="tabpanel"
          aria-labelledby="forms-tab"
        >
          <.live_component
            module={HousingAppWeb.Components.TenantForms}
            id="tenant-forms-component"
            current_user_tenant={@current_user_tenant}
            current_tenant={@current_tenant}
          >
          </.live_component>
        </div>
        <div
          class="hidden p-4 rounded-lg bg-gray-50 dark:bg-gray-800"
          id="time-periods"
          role="tabpanel"
          aria-labelledby="time-periods-tab"
        >
          <.live_component
            module={HousingAppWeb.Components.TimePeriodsForm}
            id="tenant-time-periods-component"
            current_user_tenant={@current_user_tenant}
            current_tenant={@current_tenant}
          >
          </.live_component>
        </div>
        <div
          class="hidden p-4 rounded-lg bg-gray-50 dark:bg-gray-800"
          id="users"
          role="tabpanel"
          aria-labelledby="users-tab"
        >
          <.live_component
            module={HousingAppWeb.Components.Settings.User}
            id="tenant-users-component"
            current_user_tenant={@current_user_tenant}
            current_tenant={@current_tenant}
            timezone={@timezone}
            locale={@locale}
          >
          </.live_component>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Account Settings")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
  end
end
