defmodule HousingAppWeb.Live.Assignments.Bookings.Form do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: live_action} = assigns) do
    assigns = assign(assigns, action: live_action)

    ~H"""
    <.simple_form :let={f} for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 :if={@action == :new} class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Booking</h2>
      <h2 :if={@action == :edit} class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update Booking</h2>
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

      <.json_form
        :if={@json_schema && (is_nil(f.data) || is_nil(f.data.data))}
        form={%{"data" => %{}} |> to_form(as: "data")}
        json_schema={@json_schema}
        embed={true}
        prefix="form"
      />

      <.json_form
        :if={@json_schema && !is_nil(f.data) && !is_nil(f.data.data)}
        form={%{"data" => f.data.data} |> to_form(as: "data")}
        json_schema={@json_schema}
        embed={true}
        prefix="form"
      />

      <:actions>
        <.button :if={@action == :new}>Create</.button>
        <.button :if={@action == :edit}>Save</.button>
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

        {:ok,
         socket
         |> assign(
           json_schema: get_booking_form_schema(current_user_tenant, tenant),
           ash_form: ash_form,
           sidebar: :assignments,
           page_title: "Edit Booking"
         )
         |> load_async_assigns()}
    end
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    ash_form =
      HousingApp.Assignments.Booking
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Assignments,
        forms: [auto?: true],
        actor: current_user_tenant,
        tenant: tenant,
        params: %{"data" => %{}}
      )
      |> to_form()

    {:ok,
     socket
     |> assign(
       json_schema: get_booking_form_schema(current_user_tenant, tenant),
       ash_form: ash_form,
       sidebar: :assignments,
       page_title: "New Booking"
     )
     |> load_async_assigns()}
  end

  def get_booking_form_schema(current_user_tenant, tenant) do
    case HousingApp.Management.get_booking_form(actor: current_user_tenant, tenant: tenant) do
      {:ok, form} -> Jason.decode!(form.json_schema)
      {:error, _} -> nil
    end
  end

  def load_async_assigns(%{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    assign_async(socket, [:beds, :profiles, :products], fn ->
      profiles =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Management.Profile.list!()
        |> Enum.sort_by(& &1.user_tenant.user.name)
        |> Enum.map(&{&1.user_tenant.user.name, &1.id})

      beds =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Assignments.Bed.list!()
        |> Enum.map(&{"#{&1.room.building.name} / #{&1.room.name} / #{&1.name}", &1.id})
        |> Enum.sort_by(fn {name, _} -> name end)

      products =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Accounting.Product.list!()
        |> Enum.map(&{"#{&1.name}, $#{&1.rate}", &1.id})
        |> Enum.sort_by(fn {name, _} -> name end)

      {:ok, %{profiles: profiles, beds: beds, products: products}}
    end)
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

  def handle_event("submit", %{"form" => params}, %{assigns: %{live_action: action}} = socket) do
    with %{source: %{valid?: true}} = ash_form <- AshPhoenix.Form.validate(socket.assigns.ash_form, params),
         {:ok, _app} <- AshPhoenix.Form.submit(ash_form) do
      {:noreply,
       socket
       |> put_flash(
         :info,
         if(action == :new, do: "Successfully created the booking.", else: "Successfully updated the booking.")
       )
       |> push_navigate(to: ~p"/assignments/bookings")}
    else
      %{source: %{valid?: false}} = ash_form ->
        IO.inspect(ash_form, label: "ash_form valid?: false")

        {:noreply,
         socket
         |> assign(ash_form: ash_form)
         |> put_flash(
           :error,
           if(action == :new,
             do: "Failed to create booking due to internal errors.",
             else: "Failed to update booking due to internal errors."
           )
         )}

      {:error, ash_form} ->
        IO.inspect(ash_form, label: "ash_form :error")

        {:noreply,
         socket
         |> assign(ash_form: ash_form)
         |> put_flash(
           :error,
           if(action == :new,
             do: "Failed to create booking due to internal errors.",
             else: "Failed to update booking due to internal errors."
           )
         )}
    end
  end
end
