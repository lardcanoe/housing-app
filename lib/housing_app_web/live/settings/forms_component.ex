defmodule HousingAppWeb.Components.TenantForms do
  @moduledoc false

  use HousingAppWeb, :live_component

  import HousingAppWeb.CoreComponents

  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true

  def render(%{ash_form: nil} = assigns) do
    ~H"""
    <div class="hidden"></div>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        autowidth={false}
        class="max-w-lg"
        for={@ash_form}
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
      >
        <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Management</h2>
        <.input type="select" options={@forms} field={@ash_form[:profile_form_id]} label="Default Profile Form" />
        <.input field={@ash_form[:form_types]} label="Form Types" />
        <.input field={@ash_form[:application_types]} label="Application Types" />

        <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Assignments</h2>
        <.input type="select" options={@forms} field={@ash_form[:building_form_id]} label="Building Form" />
        <.input type="select" options={@forms} field={@ash_form[:room_form_id]} label="Room Form" />
        <.input type="select" options={@forms} field={@ash_form[:bed_form_id]} label="Bed Form" />
        <.input type="select" options={@forms} field={@ash_form[:booking_form_id]} label="Booking Form" />

        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket |> assign(ash_form: nil, forms: [])}
  end

  def update(%{current_user_tenant: current_user_tenant, current_tenant: tenant}, socket) do
    settings =
      HousingApp.Management.TenantSetting.get_settings!(
        actor: current_user_tenant,
        tenant: tenant
      )

    ash_form =
      %{
        "profile_form_id" => settings[{:system, :profile_form_id}] || nil,
        "form_types" => settings[{:system, :form_types}] || "",
        "application_types" => settings[{:system, :application_types}] || "",
        "building_form_id" => settings[{:system, :building_form_id}] || nil,
        "room_form_id" => settings[{:system, :room_form_id}] || nil,
        "bed_form_id" => settings[{:system, :bed_form_id}] || nil,
        "booking_form_id" => settings[{:system, :booking_form_id}] || nil
      }
      |> to_form()

    {:ok,
     socket
     |> assign(
       ash_form: ash_form,
       forms: approved_forms_with_empty(current_user_tenant, tenant),
       current_user_tenant: current_user_tenant,
       current_tenant: tenant
     )}
  end

  def handle_event("validate", _data, socket) do
    # ash_form = AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, socket}
  end

  def handle_event(
        "submit",
        data,
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    ash_form =
      data
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        case HousingApp.Management.TenantSetting
             |> Ash.Changeset.new()
             |> Ash.Changeset.for_create(:create, %{namespace: :system, setting: String.to_atom(key), value: value},
               actor: current_user_tenant,
               tenant: tenant,
               upsert?: true
             )
             |> HousingApp.Management.create() do
          {:ok, setting} ->
            Map.put(acc, key, setting.value)

          _ ->
            acc
        end
      end)
      |> to_form()

    {:noreply, socket |> assign(ash_form: ash_form)}
  end
end
