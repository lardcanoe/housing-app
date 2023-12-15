defmodule HousingAppWeb.Live.Assignments.Rooms.Edit do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <.simple_form :let={f} for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update room</h2>
      <.input
        type="select"
        field={@ash_form[:building_id]}
        options={@buildings}
        label="Building"
        prompt="Select a building..."
        disabled
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

      <.json_form
        :if={@json_schema}
        form={%{"data" => f.data.data} |> to_form(as: "data")}
        json_schema={@json_schema}
        embed={true}
      />

      <:actions>
        <.button>Save</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(
        %{"id" => id},
        _session,
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    case HousingApp.Assignments.Room.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :assignments)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/assignments/rooms")}

      {:ok, app} ->
        ash_form =
          app
          |> AshPhoenix.Form.for_update(:update,
            api: HousingApp.Assignments,
            forms: [auto?: true],
            actor: current_user_tenant,
            tenant: tenant
          )
          |> to_form(as: "room")

        buildings =
          HousingApp.Assignments.Building.list!(actor: current_user_tenant, tenant: tenant)
          |> Enum.map(&{&1.name, &1.id})

        products =
          HousingApp.Accounting.Product.list!(actor: current_user_tenant, tenant: tenant)
          |> Enum.map(&{&1.name, &1.id})

        json_schema =
          case HousingApp.Management.get_room_form(actor: current_user_tenant, tenant: tenant) do
            {:ok, room_form} -> room_form.json_schema |> Jason.decode!()
            {:error, _} -> nil
          end

        {:ok,
         assign(socket,
           json_schema: json_schema,
           ash_form: ash_form,
           buildings: buildings,
           products: products,
           sidebar: :assignments,
           page_title: "Edit Room"
         )}
    end
  end

  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("submit", %{"form" => params} = payload, socket) do
    # TODO: Validate "data" against JSON schema of form
    with %{source: %{valid?: true}} = ash_form <- AshPhoenix.Form.validate(socket.assigns.ash_form, params),
         {:ok, _app} <- AshPhoenix.Form.submit(ash_form, override_params: %{"data" => payload["data"] || %{}}) do
      {:noreply,
       socket
       |> put_flash(:info, "Successfully updated the room.")
       |> push_navigate(to: ~p"/assignments/rooms")}
    else
      %{source: %{valid?: false}} = ash_form ->
        {:noreply, assign(socket, ash_form: ash_form)}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
