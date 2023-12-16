defmodule HousingAppWeb.Live.TenantSettings do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  # https://flowbite.com/blocks/application/crud-update-forms/#update-user-form
  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Account Settings</h1>

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
    """
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
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

    db_forms =
      HousingApp.Management.Form.list_approved!(actor: current_user_tenant, tenant: tenant)
      |> Enum.map(&{&1.name, &1.id})

    forms =
      [{"-- Select a default --", nil}] ++ db_forms

    {:ok, assign(socket, ash_form: ash_form, forms: forms, page_title: "Account Settings")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
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

    {:noreply, socket |> assign(ash_form: ash_form) |> put_flash(:info, "Successfully updated account settings.")}
  end
end
