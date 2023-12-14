defmodule HousingAppWeb.Live.Applications.Submissions do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :submissions} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Application Submissions"
      count={@count}
      loading={@loading}
      current_user_tenant={@current_user_tenant}
    >
    </.data_grid>
    """
  end

  def mount(
        %{"id" => id},
        _session,
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    case HousingApp.Management.Application.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :applications)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/applications")}

      {:ok, application} ->
        {:ok,
         socket
         |> assign(
           application: application,
           count: 0,
           loading: true,
           sidebar: :applications,
           page_title: "Application Submissions"
         )}
    end
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params, count: 0, loading: true)}
  end

  def handle_event(
        "load-data",
        %{},
        %{assigns: %{application: application, current_user_tenant: current_user_tenant, current_tenant: tenant}} =
          socket
      ) do
    schema = application.form.json_schema |> Jason.decode!()

    columns =
      [
        %{"field" => "metadata.user", "headerName" => "User", "pinned" => true},
        %{
          "field" => "metadata.created_at",
          "headerName" => "Submitted At",
          "type" => ["dateColumn", "nonEditableColumn"]
        }
      ] ++ HousingApp.Utils.JsonSchema.schema_to_aggrid_columns(schema)

    case HousingApp.Management.ApplicationSubmission.list_by_application(application.id,
           actor: current_user_tenant,
           tenant: tenant
         ) do
      {:ok, submissions} ->
        data =
          submissions
          |> Enum.map(
            &Enum.into(&1.data, %{"metadata" => %{"created_at" => &1.created_at, "user" => &1.user_tenant.user.name}})
          )

        {:reply, %{columns: columns, data: data}, assign(socket, loading: false, count: length(data))}

      _ ->
        {:reply, %{columns: columns, data: []}, assign(socket, loading: false, count: 0)}
    end
  end
end
