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
    <.data_grid
      id="ag-data-grid"
      header="Applications"
      count={@count}
      loading={@loading}
      drawer={HousingAppWeb.Components.Drawer.Application}
      current_user_tenant={@current_user_tenant}
      current_tenant={@current_tenant}
    >
      <:actions>
        <.link patch={~p"/applications/new"}>
          <button
            type="button"
            class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add application
          </button>
        </.link>
      </:actions>
    </.data_grid>
    """
  end

  def mount(
        _params,
        _session,
        %{assigns: %{current_user_tenant: %{user_type: :user}, current_tenant: tenant}} = socket
      ) do
    if connected?(socket) do
      HousingAppWeb.Endpoint.subscribe("application:#{tenant}:created")
      HousingAppWeb.Endpoint.subscribe("application:#{tenant}:updated")
    end

    {:ok,
     socket
     |> assign(sidebar: :applications, page_title: "Applications")
     |> load_async_assigns()}
  end

  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(params: params, loading: true, count: 0, sidebar: :applications, page_title: "Applications")}
  end

  def handle_params(
        _params,
        _url,
        %{assigns: %{current_user_tenant: %{user_type: :user}}} = socket
      ) do
    {:noreply,
     socket
     |> assign(sidebar: :applications, page_title: "Applications")
     |> load_async_assigns()}
  end

  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(params: params, loading: true, count: 0, sidebar: :applications, page_title: "Applications")}
  end

  defp load_async_assigns(
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

  def handle_info(%{event: "application-created", payload: %{payload: %{data: %{status: :approved}}}}, socket) do
    {:noreply, socket |> load_async_assigns()}
  end

  def handle_info(%{event: "application-updated", payload: %{payload: %{data: %{status: :approved}}}}, socket) do
    {:noreply, socket |> load_async_assigns()}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  def handle_event("view-row", %{"id" => id}, socket) do
    send_update(HousingAppWeb.Components.Drawer.Application, id: "drawer-right", application_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, socket |> push_navigate(to: ~p"/applications/#{id}/edit")}
  end

  def handle_event("redirect", %{"url" => url}, socket) do
    {:noreply, socket |> push_navigate(to: url)}
  end

  def handle_event("load-data", %{}, socket) do
    applications =
      socket
      |> fetch_applications()
      |> Enum.sort_by(& &1.name)
      |> map_applications()

    columns =
      [
        %{field: "name", minWidth: 200, pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
        %{field: "id", minWidth: 120, pinned: "left", hide: true},
        %{field: "status", maxWidth: 140, cellRenderer: "draftStatus"},
        %{field: "type"},
        %{field: "submission_type", headerName: "Submission Type"},
        %{field: "submissions", headerName: "Submissions", cellRenderer: "link"},
        %{field: "form", headerName: "Form", cellRenderer: "link"},
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
       data: applications
     }, assign(socket, loading: false, count: length(applications))}
  end

  defp fetch_applications(%{assigns: %{params: %{"type" => app_type}}} = socket)
       when is_binary(app_type) and app_type != "" do
    %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
    HousingApp.Management.Application.list_by_type!(app_type, actor: current_user_tenant, tenant: tenant)
  end

  defp fetch_applications(socket) do
    %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
    HousingApp.Management.Application.list!(actor: current_user_tenant, tenant: tenant)
  end

  defp map_applications(applications) do
    Enum.map(applications, fn b ->
      %{
        "id" => b.id,
        "name" => b.name,
        "status" => b.status,
        "type" => b.type,
        "submission_type" => b.submission_type,
        "submissions" => b.count_of_submissions,
        "submissions_link" => ~p"/applications/#{b.id}/submissions",
        "form" => b.form.name,
        "form_link" => ~p"/forms/#{b.form.id}/edit",
        "actions" => [["Edit"], ["View"]]
      }
    end)
  end
end
