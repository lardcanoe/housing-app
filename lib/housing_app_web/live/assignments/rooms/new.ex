defmodule HousingAppWeb.Live.Assignments.Rooms.New do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :new} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Room</h2>
      <.input
        type="select"
        field={@ash_form[:building_id]}
        options={@buildings}
        label="Building"
        prompt="Select a building..."
      />
      <.input field={@ash_form[:name]} label="Name" />
      <.input field={@ash_form[:block]} label="Block" />
      <.input type="number" field={@ash_form[:floor]} label="Floor" />
      <.input type="number" field={@ash_form[:max_capacity]} label="Max Capacity" />
      <.input
        type="select"
        field={@ash_form[:product_id]}
        options={@products}
        label="Product"
        prompt="Select a product for pricing..."
      />
      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    ash_form =
      HousingApp.Assignments.Room
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Assignments,
        forms: [auto?: true],
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    buildings =
      [actor: current_user_tenant, tenant: tenant]
      |> HousingApp.Assignments.Building.list!()
      |> Enum.map(&{&1.name, &1.id})

    products =
      [actor: current_user_tenant, tenant: tenant]
      |> HousingApp.Accounting.Product.list!()
      |> Enum.map(&{&1.name, &1.id})

    {:ok,
     assign(socket,
       ash_form: ash_form,
       buildings: buildings,
       products: products,
       sidebar: :assignments,
       page_title: "New Room"
     )}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    with %{source: %{valid?: true}} = ash_form <- AshPhoenix.Form.validate(socket.assigns.ash_form, params),
         {:ok, _app} <- AshPhoenix.Form.submit(ash_form) do
      {:noreply,
       socket
       |> put_flash(:info, "Successfully created the room.")
       |> push_navigate(to: ~p"/assignments/rooms")}
    else
      %{source: %{valid?: false}} = ash_form ->
        {:noreply, assign(socket, ash_form: ash_form)}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
