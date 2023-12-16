defmodule HousingAppWeb.Live.Assignments.Bookings.Edit do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <.simple_form :let={f} for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update booking</h2>
      <.input type="select" field={@ash_form[:profile_id]} options={@profiles} label="Profile" prompt="Select a profile..." />
      <.input type="select" field={@ash_form[:bed_id]} options={@beds} label="Bed" prompt="Select a bed..." />
      <.input type="select" field={@ash_form[:product_id]} options={@products} label="Rate" prompt="Select a rate..." />
      <.input type="date" field={@ash_form[:start_at]} label="Start At" />
      <.input type="date" field={@ash_form[:end_at]} label="End At" />

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
    case HousingApp.Assignments.Booking.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :assignments)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/assignments/bookings")}

      {:ok, app} ->
        ash_form =
          app
          |> AshPhoenix.Form.for_update(:update,
            api: HousingApp.Assignments,
            forms: [auto?: true],
            actor: current_user_tenant,
            tenant: tenant
          )
          |> to_form()

        json_schema =
          case HousingApp.Management.get_booking_form(actor: current_user_tenant, tenant: tenant) do
            {:ok, form} -> form.json_schema |> Jason.decode!()
            {:error, _} -> nil
          end

        beds =
          HousingApp.Assignments.Bed.list!(actor: current_user_tenant, tenant: tenant)
          |> Enum.map(&{"#{&1.room.building.name} / #{&1.room.name} / #{&1.name}", &1.id})

        profiles =
          HousingApp.Management.Profile.list!(actor: current_user_tenant, tenant: tenant)
          |> Enum.map(&{&1.user_tenant.user.name, &1.id})

        products =
          HousingApp.Accounting.Product.list!(actor: current_user_tenant, tenant: tenant)
          |> Enum.map(&{"#{&1.name}, $#{&1.rate}", &1.id})

        {:ok,
         assign(socket,
           ash_form: ash_form,
           json_schema: json_schema,
           beds: beds,
           profiles: profiles,
           products: products,
           sidebar: :assignments,
           page_title: "Edit Booking"
         )}
    end
  end

  def handle_event(
        "validate",
        %{"_target" => ["form", "bed_id"], "form" => %{"bed_id" => bed_id} = params},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      )
      when is_binary(bed_id) and bed_id != "" do
    params =
      case HousingApp.Assignments.Bed.get_by_id(bed_id, actor: current_user_tenant, tenant: tenant) do
        {:ok, bed} -> Map.put(params, "product_id", bed.room.product_id)
        _ -> params
      end

    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
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
       |> put_flash(:info, "Successfully updated the booking.")
       |> push_navigate(to: ~p"/assignments/bookings")}
    else
      %{source: %{valid?: false}} = ash_form ->
        {:noreply, assign(socket, ash_form: ash_form)}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
