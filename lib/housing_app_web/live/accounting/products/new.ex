defmodule HousingAppWeb.Live.Accounting.Products.New do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :new} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Product</h2>
      <.input field={@ash_form[:name]} label="Name" />
      <.input field={@ash_form[:description]} label="Description" />
      <.input type="number" step=".01" field={@ash_form[:rate]} label="Rate" />
      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    ash_form =
      HousingApp.Accounting.Product
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Accounting,
        forms: [auto?: true],
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    {:ok, assign(socket, ash_form: ash_form, sidebar: :accounting, page_title: "New Product")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
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
       |> put_flash(:info, "Successfully created the product.")
       |> push_navigate(to: ~p"/accounting/products")}
    else
      %{source: %{valid?: false}} = ash_form ->
        {:noreply, assign(socket, ash_form: ash_form)}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
