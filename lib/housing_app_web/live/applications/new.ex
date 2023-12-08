defmodule HousingAppWeb.Live.Applications.New do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :new} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Application</h2>
      <.input field={@ash_form[:name]} label="Name" />
      <.input type="select" field={@ash_form[:form_id]} options={@forms} label="Form" prompt="Select a form..." />
      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    ash_form =
      HousingApp.Management.Application
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Management,
        forms: [auto?: true],
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    forms = HousingApp.Management.Form.list!(actor: current_user_tenant, tenant: tenant) |> Enum.map(&{&1.name, &1.id})

    {:ok, assign(socket, ash_form: ash_form, forms: forms, sidebar: :applications, page_title: "New Application")}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    # Database constraints will validate that :form_id is a valid form for the current tenant
    with %{source: %{valid?: true}} = ash_form <- AshPhoenix.Form.validate(socket.assigns.ash_form, params),
         {:ok, _app} <- AshPhoenix.Form.submit(ash_form) do
      {:noreply,
       socket
       |> put_flash(:info, "Successfully created the application.")
       |> push_navigate(to: ~p"/applications")}
    else
      %{source: %{valid?: false}} = ash_form ->
        {:noreply, assign(socket, ash_form: ash_form)}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
