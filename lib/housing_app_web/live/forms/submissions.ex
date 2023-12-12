defmodule HousingAppWeb.Live.Forms.Submissions do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :submissions} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Form Submissions</h1>

    <div id="ag-data-grid" style="width: 100%; height: 400px;" class="ag-theme-quartz-dark" phx-hook="AgGrid"></div>
    """
  end

  def mount(
        %{"id" => id},
        _session,
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    case HousingApp.Management.Form.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :forms)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/forms")}

      {:ok, form} ->
        {:ok, socket |> assign(form: form, sidebar: :forms, page_title: "Form Submissions")}
    end
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
  end

  def handle_event(
        "load-data",
        %{},
        %{assigns: %{form: form, current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    schema = form.json_schema |> Jason.decode!()

    columns =
      HousingApp.Utils.JsonSchema.schema_to_aggrid_columns(schema) ++
        [
          %{
            "field" => "metadata.created_at",
            "headerName" => "Created At",
            "type" => ["dateColumn", "nonEditableColumn"]
          },
          %{"field" => "metadata.user", "headerName" => "User"}
        ]

    case HousingApp.Management.FormSubmission.list_by_form(form.id, actor: current_user_tenant, tenant: tenant) do
      {:ok, submissions} ->
        data =
          submissions
          |> Enum.map(
            &Enum.into(&1.data, %{"metadata" => %{"created_at" => &1.created_at, "user" => &1.user_tenant.user.name}})
          )

        {:reply, %{columns: columns, data: data}, socket}

      _ ->
        {:reply, %{columns: columns, data: []}, socket}
    end
  end
end
