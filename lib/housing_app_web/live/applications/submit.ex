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

  def handle_event("submit", data, socket) do
    ref_schema = ExJsonSchema.Schema.resolve(socket.assigns.json_schema)

    case ExJsonSchema.Validator.validate(ref_schema, data) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Thank you for your submission!")
         |> push_navigate(to: ~p"/applications")}

      {:error, _errors} ->
        {:noreply, socket |> put_flash(:error, "Errors present in form submission.")}
    end
  end
end