defmodule HousingAppWeb.Live.Applications.Index do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index, current_user_tenant: %{user_type: :user}} = assigns) do
    ~H"""
    <p :if={@applications.loading || @submissions.loading}>Loading...</p>
    <div :if={@applications.ok? && @applications.result} class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
      <div
        :for={application <- @applications.result}
        class="max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700"
      >
        <.link patch={~p"/applications/#{application.id}"}>
          <h5 class="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
            <%= application.name %>
          </h5>
        </.link>
        <p class="mb-3 font-normal text-gray-700 dark:text-gray-400">
          <%= application.description %>
        </p>
        <.link
          patch={~p"/applications/#{application.id}"}
          class="inline-flex items-center px-3 py-2 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
        >
          <span :if={application.submission_type == :once && MapSet.member?(@submissions.result, application.id)}>
            Resubmit
          </span>
          <span :if={application.submission_type != :once || !MapSet.member?(@submissions.result, application.id)}>
            Submit
          </span>
          <svg
            class="rtl:rotate-180 w-3.5 h-3.5 ms-2"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 14 10"
          >
            <path
              stroke="currentColor"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M1 5h12m0 0L9 1m4 4L9 9"
            />
          </svg>
        </.link>
      </div>
    </div>
    """
  end

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Applications</h1>

    <p :if={@applications.loading}>Loading...</p>
    <.table
      :if={@applications.ok? and @applications.result}
      id="applications"
      rows={@applications.result}
      pagination={false}
      row_id={fn row -> "applications-row-#{row.id}" end}
    >
      <:button>
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
        <.link patch={~p"/applications/new"}>
          Add application
        </.link>
      </:button>
      <:col :let={application} label="name">
        <.link patch={~p"/applications/#{application.id}"}><%= application.name %></.link>
      </:col>
      <:col :let={application} label="type">
        <%= application.type %>
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
      <:col :let={application} label="form">
        <.link patch={~p"/applications/#{application.form_id}/edit"}><%= application.form.name %></.link>
      </:col>
      <:col :let={application} label="Submissions">
        <.link patch={~p"/applications/#{application.id}/submissions"}>
          <%= application.count_of_submissions %>
        </.link>
      </:col>
      <:action :let={application}>
        <.link
          patch={~p"/applications/#{application.id}/edit"}
          class="block py-2 px-4 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
        >
          Edit
        </.link>
      </:action>
      <:action :let={application}>
        <.link
          patch={~p"/applications/#{application.id}/submissions"}
          class="block py-2 px-4 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
        >
          View submissions
        </.link>
      </:action>
    </.table>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(sidebar: :applications, page_title: "Applications")
     |> load_async_assigns()}
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(sidebar: :applications, page_title: "Applications")
     |> load_async_assigns()}
  end

  def load_async_assigns(
        %{
          assigns: %{
            current_user_tenant: %{user_type: :user} = current_user_tenant,
            current_tenant: tenant
          }
        } = socket
      ) do
    socket
    |> assign_async([:applications, :submissions], fn ->
      applications =
        if connected?(socket) do
          HousingApp.Management.Application.list_approved!(actor: current_user_tenant, tenant: tenant)
          |> Enum.sort_by(& &1.name)
        else
          []
        end

      submissions =
        if connected?(socket) do
          HousingApp.Management.ApplicationSubmission.list_by_user_tenant!(current_user_tenant.id,
            actor: current_user_tenant,
            tenant: tenant
          )
          |> MapSet.new(& &1.application_id)
        else
          MapSet.new()
        end

      {:ok,
       %{
         applications: applications,
         submissions: submissions
       }}
    end)
  end

  def load_async_assigns(%{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    socket
    |> assign_async([:applications], fn ->
      applications =
        if connected?(socket) do
          HousingApp.Management.Application.list!(actor: current_user_tenant, tenant: tenant)
          |> Enum.sort_by(& &1.name)
        else
          []
        end

      {:ok,
       %{
         applications: applications
       }}
    end)
  end
end
