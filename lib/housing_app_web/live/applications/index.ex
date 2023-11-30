defmodule HousingAppWeb.Live.Applications.Index do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index, current_user_tenant: %{role: :user}} = assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4"></div>
    """
  end

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.table id="applications" rows={@applications} pagination={false} row_id={fn row -> "applications-row-#{row.id}" end}>
      <:button>
        <svg class="h-3.5 w-3.5 mr-2" fill="currentColor" viewbox="0 0 20 20" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
          <path clip-rule="evenodd" fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" />
        </svg>
        <a href={~p"/applications/new"}>
          Add application
        </a>
      </:button>
      <:col :let={application} label="name">
        <a href={~p"/applications/#{application.id}"}><%= application.name %></a>
      </:col>
      <:col :let={application} label="status">
        <span
          :if={application.status == :draft}
          class="bg-yellow-100 text-yellow-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded dark:bg-yellow-900 dark:text-yellow-300"
        >
          Draft
        </span>
        <span
          :if={application.status == :approved}
          class="bg-green-100 text-green-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded dark:bg-green-900 dark:text-green-300"
        >
          Approved
        </span>
        <span
          :if={application.status == :archived}
          class="bg-gray-100 text-gray-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded dark:bg-gray-700 dark:text-gray-300"
        >
          Archived
        </span>
      </:col>
      <:action :let={application}>
        <a href={~p"/applications/#{application.id}/edit"} class="block py-2 px-4 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white">Edit</a>
      </:action>
    </.table>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant}} = socket) do
    applications = HousingApp.Management.list_applications!(current_user_tenant.tenant_id, actor: current_user_tenant)

    {:ok, assign(socket, applications: applications, page_title: "Applications")}
  end
end
