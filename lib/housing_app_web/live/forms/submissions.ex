defmodule HousingAppWeb.Live.Forms.Submissions do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :submissions} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Form Submissions"
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
    case HousingApp.Management.Form.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :forms)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/forms")}

      {:ok, form} ->
        {:ok, socket |> assign(form: form, count: 0, loading: true, sidebar: :forms, page_title: "Form Submissions")}
    end
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params, count: 0, loading: true)}
  end

  def handle_event(
        "load-data",
        %{},
        %{assigns: %{form: form, current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    schema = form.json_schema |> Jason.decode!()

    columns =
      [
        %{"field" => "metadata.user", "headerName" => "User", "pinned" => true},
        %{"field" => "id", "headerName" => "Id", "pinned" => true, "hide" => true},
        %{
          "field" => "metadata.created_at",
          "headerName" => "Submitted At",
          "type" => ["dateColumn", "nonEditableColumn"]
        }
      ] ++ HousingApp.Utils.JsonSchema.schema_to_aggrid_columns(schema)

    case HousingApp.Management.FormSubmission.list_by_form(form.id, actor: current_user_tenant, tenant: tenant) do
      {:ok, submissions} ->
        data =
          submissions
          |> Enum.map(
            &Enum.into(&1.data, %{
              "id" => &1.id,
              "metadata" => %{"created_at" => &1.created_at, "user" => &1.user_tenant.user.name}
            })
          )

        {:reply, %{columns: columns, data: data}, assign(socket, loading: false, count: length(data))}

      _ ->
        {:reply, %{columns: columns, data: []}, assign(socket, loading: false, count: 0)}
    end
  end
end
