defmodule HousingAppWeb.Live.Applications.New do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :new} = assigns) do
    ~H"""
    <.simple_form for={@form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Application</h2>
      <.input field={@form[:name]} label="Name" />
      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    form =
      HousingApp.Management.Application
      |> AshPhoenix.Form.for_create(:create,
        api: HousingApp.Management,
        forms: [auto?: true],
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    {:ok, assign(socket, form: form, page_title: "New Application")}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("submit", %{"form" => params}, %{assigns: %{current_user_tenant: current_user_tenant}} = socket) do
    params =
      Enum.into(params, %{
        tenant_id: current_user_tenant.tenant_id,
        json_schema: "{}",
        status: :draft
      })

    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully created the application.")
         |> push_navigate(to: ~p"/applications")}

      {:error, form} ->
        # IO.inspect(form, label: :error)
        {:noreply, assign(socket, form: form)}
    end
  end
end
