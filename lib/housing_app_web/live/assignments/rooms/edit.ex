defmodule HousingAppWeb.Live.Assignments.Rooms.Edit do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(assigns) do
    ~H"""
    <.simple_form :let={f} for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Room</h2>
      <.input
        type="select"
        field={@ash_form[:building_id]}
        options={@buildings}
        label="Building"
        prompt="Select a building..."
        {if(@ash_form.source.action == :update, do: [{"disabled", ""}], else: [])}
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
        form={%{"data" => if(is_nil(f.data), do: %{}, else: f.data.data)} |> to_form(as: "data")}
        json_schema={@json_schema}
        embed={true}
      />

      <:actions>
        <.button>Save</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

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

        {:ok,
         socket
         |> assign(
           ash_form: ash_form,
           sidebar: :assignments,
           page_title: "Edit Room"
         )
         |> load_assigns()}
    end
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

    {:ok,
     socket
     |> assign(
       ash_form: ash_form,
       sidebar: :assignments,
       page_title: "New Room"
     )
     |> load_assigns()}
  end

  defp load_assigns(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    buildings =
      [actor: current_user_tenant, tenant: tenant]
      |> HousingApp.Assignments.Building.list!()
      |> Enum.map(&{&1.name, &1.id})

    products =
      [actor: current_user_tenant, tenant: tenant]
      |> HousingApp.Accounting.Product.list!()
      |> Enum.map(&{&1.name, &1.id})

    json_schema =
      case HousingApp.Management.Service.get_room_form(actor: current_user_tenant, tenant: tenant) do
        {:ok, room_form} -> Jason.decode!(room_form.json_schema)
        {:error, _} -> nil
      end

    assign(socket,
      buildings: buildings,
      products: products,
      json_schema: json_schema
    )
  end

  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("submit", %{"form" => params} = payload, socket) do
    # TODO: Validate "data" against JSON schema of form
    params = Map.put(params, "data", payload["data"] || %{})

    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully saved the room.")
         |> push_navigate(to: ~p"/assignments/rooms")}

      {:error, ash_form} ->
        dbg(ash_form)
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
