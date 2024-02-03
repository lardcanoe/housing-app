defmodule HousingAppWeb.Live.Applications.Submissions do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingApp.Cldr, only: [format_time: 2]
  import HousingAppWeb.Components.DataGrid

  on_mount HousingAppWeb.LiveLocale

  def render(%{live_action: :submissions} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header={"#{@application.name} Submissions"}
      count={@count}
      loading={@loading}
      current_user_tenant={@current_user_tenant}
    >
      <:pills>
        <.link patch={~p"/applications/#{@application.id}/submissions"}>
          <button
            :if={Enum.any?(@statuses)}
            type="button"
            class="inline-flex items-center px-5 py-2.5 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
          >
            All
          </button>
        </.link>
        <.link :for={status <- @statuses} patch={~p"/applications/#{@application.id}/submissions?status=#{status.status}"}>
          <button
            type="button"
            class={[
              "inline-flex items-center px-5 py-2.5 text-sm font-medium text-center rounded-lg focus:ring-4 focus:outline-none",
              status_class(status.status)
            ]}
          >
            <%= Atom.to_string(status.status) |> HousingApp.Utils.String.titlize() %>
            <span class="inline-flex items-center justify-center w-4 h-4 ms-2 text-xs font-semibold text-blue-800 bg-blue-200 rounded-full">
              <%= status.count %>
            </span>
          </button>
        </.link>
      </:pills>
    </.data_grid>
    """
  end

  defp status_class(:started),
    do: "text-white bg-yellow-400 hover:bg-yellow-500 focus:ring-yellow-300 dark:focus:ring-yellow-900"

  defp status_class(:completed),
    do:
      "bg-green-700 hover:bg-green-800 focus:ring-green-300 dark:bg-green-600 dark:hover:bg-green-700 dark:focus:ring-green-800"

  defp status_class(:rejected),
    do:
      "text-white bg-red-700 hover:bg-red-800 focus:ring-red-300 dark:bg-red-600 dark:hover:bg-red-700 dark:focus:ring-red-900"

  def mount(%{"id" => id}, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Management.Application.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :applications)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/applications")}

      {:ok, application} ->
        {:ok,
         assign(socket,
           application: application,
           count: 0,
           loading: true,
           sidebar: :applications,
           page_title: "Application Submissions"
         )}
    end
  end

  def handle_params(%{"status" => status}, _uri, socket) when status in ["started", "completed", "rejected"] do
    {:noreply, socket |> assign(status: String.to_atom(status)) |> load_statuses()}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket |> assign(status: nil) |> load_statuses()}
  end

  defp load_statuses(socket) do
    %{application: application, current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    statuses =
      application.id
      |> HousingApp.Management.ApplicationSubmission.get_statuses!(
        actor: current_user_tenant,
        tenant: tenant
      )
      |> Enum.reduce(%{}, fn s, acc ->
        Map.update(acc, s.status, 1, &(&1 + 1))
      end)
      |> Enum.map(fn {k, v} -> %{status: k, count: v} end)

    assign(socket, statuses: statuses)
  end

  def handle_event("load-data", %{}, %{assigns: %{application: application}} = socket) do
    %{
      status: status,
      locale: locale,
      timezone: timezone,
      current_user_tenant: current_user_tenant,
      current_tenant: tenant
    } = socket.assigns

    schema = Jason.decode!(application.form.json_schema)

    # FUTURE: convert a reference object to a name/link tuple
    # "room" => %{
    #   "format" => "uuid",
    #   "propertyOrder" => 0,
    #   "reference" => "inventory/rooms",
    #   "type" => "string"
    # }

    columns =
      [
        %{"field" => "metadata.user", "headerName" => "User", "pinned" => true},
        %{"field" => "id", "headerName" => "Id", "pinned" => true, "hide" => true},
        %{"field" => "status", "maxWidth" => 140, "cellRenderer" => "draftStatus"},
        %{
          "field" => "metadata.created_at",
          "headerName" => "Submitted At",
          "type" => ["dateColumn", "nonEditableColumn"]
        }
      ] ++ HousingApp.Utils.JsonSchema.schema_to_aggrid_columns(schema)

    case HousingApp.Management.ApplicationSubmission.list_by_application(application.id, status,
           actor: current_user_tenant,
           tenant: tenant
         ) do
      {:ok, submissions} ->
        data =
          Enum.map(
            submissions,
            &Enum.into(dbg(&1.data), %{
              "id" => &1.id,
              "status" => &1.status,
              "metadata" => %{
                "created_at" =>
                  if(application.submission_type == :once,
                    do: format_time(&1.updated_at, locale: locale, timezone: timezone, format: :short),
                    else: format_time(&1.created_at, locale: locale, timezone: timezone, format: :short)
                  ),
                "user" => &1.user_tenant.user.name
              }
            })
          )

        {:reply, %{columns: columns, data: data}, assign(socket, loading: false, count: length(data))}

      _ ->
        {:reply, %{columns: columns, data: []}, assign(socket, loading: false, count: 0)}
    end
  end
end
