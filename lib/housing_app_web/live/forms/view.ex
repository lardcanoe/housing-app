defmodule HousingAppWeb.Live.Forms.View do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :view} = assigns) do
    ~H"""
    <div class="bg-white dark:bg-white">
      <div id="json-schema-form" phx-hook="JSONSchemaForm" />
    </div>
    """
  end

  def mount(%{"id" => id}, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    case HousingApp.Management.Form.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/forms")}

      {:ok, form} ->
        {:ok, assign(socket, json_schema: form.json_schema |> Jason.decode!(), page_title: "View Form")}
    end
  end

  def handle_event("load-schema", _params, socket) do
    {:reply, %{schema: socket.assigns.json_schema}, socket}
  end

  def handle_event("submit", _data, socket) do
    {:noreply, socket}
  end
end
