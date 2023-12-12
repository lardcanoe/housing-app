defmodule HousingAppWeb.Live.Assignments.Bookings.New do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :new} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Booking</h2>
      <.async_result :let={profiles} assign={@profiles}>
        <:loading>
          <.input
            type="select"
            field={@ash_form[:profile_id]}
            options={[]}
            label="Profile"
            prompt="Loading profiles..."
            disabled
          />
        </:loading>
        <:failed :let={reason}><%= reason %></:failed>
        <.input
          type="select"
          field={@ash_form[:profile_id]}
          options={profiles}
          label="Profile"
          prompt="Select a profile..."
        />
      </.async_result>
      <.async_result :let={beds} assign={@beds}>
        <:loading>
          <.input type="select" field={@ash_form[:bed_id]} options={[]} label="Bed" disabled prompt="Loading beds..." />
        </:loading>
        <:failed :let={reason}><%= reason %></:failed>
        <.input type="select" field={@ash_form[:bed_id]} options={beds} label="Bed" prompt="Select a bed..." />
      </.async_result>
      <.async_result :let={products} assign={@products}>
        <:loading>
          <.input type="select" field={@ash_form[:product_id]} options={[]} label="Rate" disabled prompt="Loading rates..." />
        </:loading>
        <:failed :let={reason}><%= reason %></:failed>
        <.input type="select" field={@ash_form[:product_id]} options={products} label="Rate" prompt="Select a rate..." />
      </.async_result>
      <.input type="date" field={@ash_form[:start_at]} label="Start At" />
      <.input type="date" field={@ash_form[:end_at]} label="End At" />
      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    ash_form =
      HousingApp.Assignments.Booking
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
       page_title: "New Booking"
     )
     |> assign_async([:beds, :profiles, :products], fn ->
       profiles =
         HousingApp.Management.Profile.list!(actor: current_user_tenant, tenant: tenant)
         |> Enum.sort_by(& &1.user_tenant.user.name)
         |> Enum.map(&{&1.user_tenant.user.name, &1.id})

       beds =
         HousingApp.Assignments.Bed.list!(actor: current_user_tenant, tenant: tenant)
         |> Enum.map(&{"#{&1.room.building.name} / #{&1.room.name} / #{&1.name}", &1.id})
         |> Enum.sort_by(fn {name, _} -> name end)

       products =
         HousingApp.Accounting.Product.list!(actor: current_user_tenant, tenant: tenant)
         |> Enum.map(&{"#{&1.name}, $#{&1.rate}", &1.id})
         |> Enum.sort_by(fn {name, _} -> name end)

       {:ok,
        %{
          profiles: profiles,
          beds: beds,
          products: products
        }}
     end)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
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

  def handle_event("submit", %{"form" => params}, socket) do
    with %{source: %{valid?: true}} = ash_form <- AshPhoenix.Form.validate(socket.assigns.ash_form, params),
         {:ok, _app} <- AshPhoenix.Form.submit(ash_form) do
      {:noreply,
       socket
       |> put_flash(:info, "Successfully created the booking.")
       |> push_navigate(to: ~p"/assignments/bookings")}
    else
      %{source: %{valid?: false}} = ash_form ->
        {:noreply,
         socket |> assign(ash_form: ash_form) |> put_flash(:error, "Failed to create booking due to internal errors.")}

      {:error, ash_form} ->
        {:noreply,
         socket |> assign(ash_form: ash_form) |> put_flash(:error, "Failed to create booking due to internal errors.")}
    end
  end
end
