defmodule HousingAppWeb.Live.TenantSettings do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  # https://flowbite.com/blocks/application/crud-update-forms/#update-user-form
  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update account settings</h2>
      <.input type="select" options={@forms} field={@ash_form[:profile_form_id]} label="Default Profile Form" />
      <.input field={@ash_form[:form_types]} label="Form Types" />
      <.input field={@ash_form[:application_types]} label="Application Types" />
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
        "application_types" => settings[{:system, :application_types}] || ""
      }
      |> to_form()

    forms = HousingApp.Management.Form.list!(actor: current_user_tenant, tenant: tenant) |> Enum.map(&{&1.name, &1.id})

    {:ok, assign(socket, ash_form: ash_form, forms: forms, page_title: "Account Settings")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
  end

  def handle_event("validate", %{"profile_form_id" => _profile_form_id}, socket) do
    # ash_form = AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, socket}
  end

  def handle_event(
        "submit",
        %{"profile_form_id" => profile_form_id, "form_types" => form_types, "application_types" => application_types},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    {:ok, profile_form_id_setting} =
      HousingApp.Management.TenantSetting
      |> Ash.Changeset.new()
      |> Ash.Changeset.for_create(:create, %{namespace: :system, setting: :profile_form_id, value: profile_form_id},
        actor: current_user_tenant,
        tenant: tenant,
        upsert?: true
      )
      |> HousingApp.Management.create()

    {:ok, form_types_setting} =
      HousingApp.Management.TenantSetting
      |> Ash.Changeset.new()
      |> Ash.Changeset.for_create(:create, %{namespace: :system, setting: :form_types, value: form_types},
        actor: current_user_tenant,
        tenant: tenant,
        upsert?: true
      )
      |> HousingApp.Management.create()

    {:ok, application_types_setting} =
      HousingApp.Management.TenantSetting
      |> Ash.Changeset.new()
      |> Ash.Changeset.for_create(:create, %{namespace: :system, setting: :application_types, value: application_types},
        actor: current_user_tenant,
        tenant: tenant,
        upsert?: true
      )
      |> HousingApp.Management.create()

    ash_form =
      %{
        "profile_form_id" => profile_form_id_setting.value,
        "form_types" => form_types_setting.value,
        "application_types" => application_types_setting.value
      }
      |> to_form()

    {:noreply, socket |> assign(ash_form: ash_form) |> put_flash(:info, "Successfully updated account settings.")}
  end
end
