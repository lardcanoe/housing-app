defmodule HousingAppWeb.Live.Forms.Submissions do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingAppWeb.Components.DataGrid

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

  def mount(%{"id" => id}, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Management.Form.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :forms)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/forms")}

      {:ok, form} ->
        {:ok, assign(socket, form: form, count: 0, loading: true, sidebar: :forms, page_title: "Form Submissions")}
    end
  end

  def handle_event("load-data", %{}, %{assigns: %{form: form}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    schema = Jason.decode!(form.json_schema)

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
          Enum.map(
            submissions,
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
