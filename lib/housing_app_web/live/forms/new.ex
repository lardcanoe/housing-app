defmodule HousingAppWeb.Live.Forms.New do
  @moduledoc false
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :new} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Form</h2>
      <.input field={@ash_form[:name]} label="Name" />
      <.input field={@ash_form[:description]} label="Description" />
      <.input type="textarea" field={@ash_form[:json_schema]} label="Schema" />
      <.input field={@ash_form[:type]} label="Type" />
      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    ash_form =
      HousingApp.Management.Form
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Management,
        forms: [auto?: true],
        prepare_params: fn p, _ ->
          Map.put(p, "tenant_id", current_user_tenant.tenant_id)
        end,
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    {:ok, assign(socket, ash_form: ash_form, sidebar: :forms, page_title: "New Form")}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully created the form.")
         |> push_navigate(to: ~p"/forms")}

      {:error, ash_form} ->
        IO.inspect(ash_form)
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
