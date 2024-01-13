defmodule HousingAppWeb.Live.Accounting.Products.Edit do
  @moduledoc false
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update product</h2>
      <.input field={@ash_form[:name]} label="Name" />
      <.input field={@ash_form[:description]} label="Description" />
      <.input type="number" step=".01" field={@ash_form[:rate]} label="Rate" />
      <:actions>
        <.button>Save</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Accounting.Product.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :accounting)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/accounting/products")}

      {:ok, app} ->
        ash_form =
          app
          |> AshPhoenix.Form.for_update(:update,
            api: HousingApp.Accounting,
            forms: [auto?: true],
            actor: current_user_tenant,
            tenant: tenant
          )
          |> to_form()

        {:ok,
         assign(socket,
           ash_form: ash_form,
           sidebar: :accounting,
           page_title: "Edit Product"
         )}
    end
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
         |> put_flash(:info, "Successfully updated the product.")
         |> push_navigate(to: ~p"/accounting/products")}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
