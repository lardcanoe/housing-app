defmodule HousingAppWeb.Live.Forms.Submissions do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :submissions} = assigns) do
    ~H"""
    <.table id="submissions" rows={@submissions} pagination={false} row_id={fn row -> "submissions-row-#{row.id}" end}>
      <:col :let={submission} :if={@current_user.role == :platform_admin} label="id">
        <%= submission.id %>
      </:col>
      <:col :let={submission} label="name">
        <%= submission.user_tenant.user.name %>
      </:col>
      <:col :let={submission} label="Date">
        <%= submission.created_at %>
      </:col>
    </.table>
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
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/forms")}

      {:ok, form} ->
        case HousingApp.Management.FormSubmission.list_by_form(form.id, actor: current_user_tenant, tenant: tenant) do
          {:ok, submissions} ->
            {:ok, assign(socket, submissions: submissions, page_title: "Form Submissions")}

          _ ->
            {:ok,
             socket
             |> assign(submissions: [], page_title: "Form Submissions")
             |> put_flash(:error, "Error loading submissions.")}
        end
    end
  end
end
