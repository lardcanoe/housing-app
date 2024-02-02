defmodule HousingAppWeb.Live.Applications.Index do
  @moduledoc false
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingAppWeb.Components.DataGrid

  alias HousingAppWeb.Components.FilteredResource

  require Ash.Query

  def render(%{live_action: :index, current_user_tenant: %{user_type: :user}} = assigns) do
    ~H"""
    <p :if={@applications.loading || @submissions.loading}>Loading...</p>
    <div :if={@applications.ok? && @applications.result} class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
      <div
        :for={application <- @applications.result}
        class="max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700"
      >
        <.link navigate={~p"/applications/#{application.id}"}>
          <h5 class="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
            <%= application.name %>
          </h5>
        </.link>
        <p class="mb-3 font-normal text-gray-700 dark:text-gray-400">
          <%= application.description %>
        </p>
        <.link
          navigate={~p"/applications/#{application.id}"}
          class="inline-flex items-center px-3 py-2 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
        >
          <span :if={application.submission_type == :once && :completed == Map.get(@submissions.result, application.id)}>
            Update
          </span>
          <span :if={application.submission_type == :once && :started == Map.get(@submissions.result, application.id)}>
            Continue
          </span>
          <span :if={application.submission_type == :once && :rejected == Map.get(@submissions.result, application.id)}>
            Resubmit
          </span>
          <span :if={application.submission_type != :once || !Map.has_key?(@submissions.result, application.id)}>
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
        <.button
          id="delete-button"
          data-selected={JS.remove_class("hidden", to: "#delete-button")}
          data-empty={JS.add_class("hidden", to: "#delete-button")}
          type="delete"
          class="hidden"
          phx-click="delete-selected"
        >
          Delete selected
        </.button>
        <.link navigate={~p"/applications/new"}>
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

  def mount(_params, _session, %{assigns: %{current_user_tenant: %{user_type: :user}, current_tenant: tenant}} = socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(HousingApp.PubSub, "application:#{tenant}:created")
      Phoenix.PubSub.subscribe(HousingApp.PubSub, "application:#{tenant}:updated")
    end

    {:ok,
     socket
     |> assign(selected_ids: [], sidebar: :applications, page_title: "Applications")
     |> load_async_assigns()}
  end

  def mount(params, _session, socket) do
    {:ok,
     assign(socket,
       params: params,
       selected_ids: [],
       loading: true,
       count: 0,
       sidebar: :applications,
       page_title: "Applications"
     )}
  end

  # Need for "link patch" to work
  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
  end

  defp load_async_assigns(
         %{assigns: %{current_user_tenant: %{user_type: :user} = current_user_tenant, current_tenant: tenant}} = socket
       ) do
    assign_async(socket, [:applications, :submissions], fn ->
      {:ok, profile} =
        HousingApp.Management.Profile.get_by_user_tenant(current_user_tenant.id,
          actor: current_user_tenant,
          tenant: tenant
        )

      applications =
        if connected?(socket) do
          [actor: current_user_tenant, tenant: tenant]
          |> HousingApp.Management.Application.list_approved!()
          |> Enum.filter(fn app ->
            HousingApp.Management.Service.profile_meets_application_conditions?(profile, app,
              actor: current_user_tenant,
              tenant: tenant
            )
          end)
          |> Enum.sort_by(& &1.name)
        else
          []
        end

      submissions =
        if connected?(socket) do
          current_user_tenant.id
          |> HousingApp.Management.ApplicationSubmission.list_by_user_tenant!(
            actor: current_user_tenant,
            tenant: tenant
          )
          |> Map.new(&{&1.application_id, &1.status})
        else
          Map.new()
        end

      {:ok, %{selected_ids: [], applications: applications, submissions: submissions}}
    end)
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{event: "application-created", payload: %{payload: %{data: %{status: :approved}}}},
        socket
      ) do
    {:noreply, load_async_assigns(socket)}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{event: "application-updated", payload: %{payload: %{data: %{status: :approved}}}},
        socket
      ) do
    {:noreply, load_async_assigns(socket)}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  def handle_event("view-row", %{"id" => id}, socket) do
    send_update(HousingAppWeb.Components.Drawer.Application, id: "drawer-right", application_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/applications/#{id}/edit")}
  end

  def handle_event("copy-row", %{"id" => id}, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    with {:get, {:ok, application}} <-
           {:get, HousingApp.Management.Application.get_by_id(id, actor: current_user_tenant, tenant: tenant)},
         {:copy, {:ok, _copied_app}} <-
           {:copy, HousingApp.Management.Application.copy(application, actor: current_user_tenant, tenant: tenant)} do
      {:noreply,
       socket
       |> put_flash(:info, "Copied application")
       |> push_event("ag-grid:refresh", %{})}
    else
      {:copy, {:error, _}} ->
        {:noreply, put_flash(socket, :error, "Failed to copy")}

      {:get, {:error, _}} ->
        {:noreply, put_flash(socket, :error, "Not found")}
    end
  end

  def handle_event("redirect", %{"url" => url}, socket) do
    {:noreply, push_navigate(socket, to: url)}
  end

  def handle_event("selection-changed", params, socket) do
    {:noreply, FilteredResource.handle_selection_changed(socket, params)}
  end

  def handle_event("delete-selected", %{}, %{assigns: %{selected_ids: []}} = socket) do
    {:noreply, assign(socket, selected_ids: [])}
  end

  def handle_event("delete-selected", %{}, %{assigns: %{selected_ids: selected_ids}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    HousingApp.Management.Application
    |> Ash.Query.for_read(:read, actor: current_user_tenant, tenant: tenant)
    |> Ash.Query.filter(id in ^selected_ids and is_nil(archived_at))
    |> HousingApp.Management.read!()
    |> Enum.each(fn app ->
      app
      |> Ash.Changeset.for_destroy(:archive)
      |> HousingApp.Management.destroy!(actor: current_user_tenant, tenant: tenant)
    end)

    {:noreply,
     socket
     |> assign(selected_ids: [])
     |> push_event("js-exec", %{to: "#delete-button", attr: "data-empty"})
     |> push_event("ag-grid:refresh", %{})}
  end

  def handle_event("load-data", %{}, socket) do
    applications =
      socket
      |> fetch_applications()
      |> Enum.sort_by(& &1.name)
      |> map_applications()

    columns =
      [
        %{field: "name", minWidth: 300, pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
        %{field: "id", minWidth: 120, pinned: "left", hide: true},
        %{field: "status", maxWidth: 140, cellRenderer: "draftStatus"},
        %{field: "type"},
        %{field: "submission_type", headerName: "Submission Type"},
        %{field: "submissions", headerName: "Submissions", cellRenderer: "link"},
        %{field: "form", headerName: "Form", cellRenderer: "link"},
        %{field: "time_period", headerName: "Time Period"},
        %{
          field: "actions",
          pinned: "right",
          minWidth: 180,
          maxWidth: 180,
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
     }, assign(socket, selected_ids: [], loading: false, count: length(applications))}
  end

  defp fetch_applications(%{assigns: %{params: %{"type" => app_type}}} = socket)
       when is_binary(app_type) and app_type != "" do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns
    HousingApp.Management.Application.list_by_type!(app_type, nil, actor: current_user_tenant, tenant: tenant)
  end

  defp fetch_applications(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns
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
        "time_period" => if(b.time_period, do: b.time_period.name, else: ""),
        "form" => b.form.name,
        "form_link" => ~p"/forms/#{b.form.id}/edit",
        "actions" => [["Edit"], ["Copy"], ["View"]]
      }
    end)
  end
end
