defmodule HousingAppWeb.Live.Applications.Submit do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :submit} = assigns) do
    ~H"""
    <div class="bg-white dark:bg-white">
      <div id="json-schema-form" phx-hook="JSONSchemaForm" />
      <.button id="json-schema-form-submit" type="submit">
        Save
      </.button>
    </div>
    """
  end

  def mount(%{"id" => id}, _session, %{assigns: %{current_user_tenant: current_user_tenant}} = socket) do
    case HousingApp.Management.get_application!(id, current_user_tenant.tenant_id, actor: current_user_tenant) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/applications")}

      app ->
        {:ok, assign(socket, json_schema: app.json_schema |> Jason.decode!(), page_title: "Submit Application")}
    end
  rescue
    _ ->
      {:ok,
       socket
       |> put_flash(:error, "Not found")
       |> push_navigate(to: ~p"/applications")}
  end

  def handle_event("load-schema", _params, socket) do
    {:reply, %{schema: socket.assigns.json_schema}, socket}
  end
end
