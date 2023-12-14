defmodule HousingAppWeb.Live.Applications.Index do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index, current_user_tenant: %{user_type: :user}} = assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4"></div>
    """
  end

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Applications</h1>

    <.table id="applications" rows={@applications} pagination={false} row_id={fn row -> "applications-row-#{row.id}" end}>
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

  def mount(params, _session, socket) do
    case fetch_applications(params, socket) do
      {:ok, applications} ->
        {:ok, assign(socket, applications: applications, sidebar: :applications, page_title: "Applications")}

      _ ->
        {:ok,
         socket
         |> assign(applications: [], sidebar: :applications, page_title: "Applications")
         |> put_flash(:error, "Error loading applications.")}
    end
  end

  def handle_params(params, _url, socket) do
    case fetch_applications(params, socket) do
      {:ok, applications} ->
        {:noreply, assign(socket, applications: applications, sidebar: :applications, page_title: "Application")}

      _ ->
        {:noreply,
         socket
         |> assign(applications: [], sidebar: :applications, page_title: "Application")
         |> put_flash(:error, "Error loading applications.")}
    end
  end

  defp fetch_applications(
         %{"type" => type},
         %{
           assigns: %{current_user_tenant: current_user_tenant, current_tenant: current_tenant}
         } = socket
       )
       when is_binary(type) and type != "" do
    if connected?(socket) do
      case HousingApp.Management.Application.list_by_type(type, actor: current_user_tenant, tenant: current_tenant) do
        {:ok, applications} -> {:ok, applications}
        _ -> {:error, []}
      end
    else
      {:ok, []}
    end
  end

  defp fetch_applications(
         _type,
         %{
           assigns: %{current_user_tenant: current_user_tenant, current_tenant: current_tenant}
         } = socket
       ) do
    if connected?(socket) do
      case HousingApp.Management.Application.list(actor: current_user_tenant, tenant: current_tenant) do
        {:ok, applications} -> {:ok, applications}
        _ -> {:error, []}
      end
    else
      {:ok, []}
    end
  end
end
