defmodule HousingAppWeb.Live.Forms.New do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :new} = assigns) do
    ~H"""
    <.simple_form for={@form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Form</h2>
      <.input field={@form[:name]} label="Name" />
      <.input type="textarea" field={@form[:json_schema]} label="Schema" />
      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    form =
      HousingApp.Management.Form
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Management,
        forms: [auto?: true],
        prepare_params: fn p, _ ->
          p
          |> Map.put("tenant_id", current_user_tenant.tenant_id)
        end,
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    {:ok, assign(socket, form: form, sidebar: :forms, page_title: "New Form")}
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
       |> put_flash(:info, "Successfully created the form.")
       |> push_navigate(to: ~p"/forms")}
    else
      %{source: %{valid?: false}} = form ->
        {:noreply, assign(socket, form: form)}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end
end
