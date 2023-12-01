defmodule HousingAppWeb.Live.Applications.Edit do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <.simple_form for={@form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update application</h2>
      <.input field={@form[:name]} label="Name" />
      <.input type="textarea" field={@form[:json_schema]} label="Schema" />
      <:actions>
        <.button>Save</.button>
        <.button :if={false} type="delete">Delete</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(%{"id" => id}, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    case HousingApp.Management.get_application!(id, current_user_tenant.tenant_id, actor: current_user_tenant) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/applications")}

      app ->
        form =
          app
          |> AshPhoenix.Form.for_update(:update,
            api: HousingApp.Management,
            forms: [auto?: true],
            actor: current_user_tenant,
            tenant: tenant
          )
          |> to_form()

        {:ok, assign(socket, form: form, page_title: "Edit Application")}
    end
  rescue
    _ ->
      {:ok,
       socket
       |> put_flash(:error, "Not found")
       |> push_navigate(to: ~p"/applications")}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    with %{source: %{valid?: true}} = form <- AshPhoenix.Form.validate(socket.assigns.form, params),
         {:ok, _app} <- AshPhoenix.Form.submit(form) do
      {:noreply,
       socket
       |> put_flash(:info, "Successfully updated the application.")
       |> push_navigate(to: ~p"/applications")}
    else
      %{source: %{valid?: false}} = form ->
        {:noreply, assign(socket, form: form)}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end
end
