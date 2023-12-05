defmodule HousingAppWeb.Live.TenantSettings do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  # https://flowbite.com/blocks/application/crud-update-forms/#update-user-form
  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update account settings</h2>
      <.input type="select" options={@forms} field={@ash_form[:profile_form_id]} label="Default Profile Form" />
      <:actions>
        <.button>Save</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    profile_form_id =
      case HousingApp.Management.TenantSetting.get_setting(:system, :profile_form_id,
             actor: current_user_tenant,
             tenant: tenant,
             not_found_error?: false
           ) do
        {:ok, setting} ->
          setting.value

        _ ->
          nil
      end

    ash_form =
      %{
        "profile_form_id" => profile_form_id
      }
      |> to_form()

    forms = HousingApp.Management.Form.list!(actor: current_user_tenant, tenant: tenant) |> Enum.map(&{&1.name, &1.id})

    {:ok, assign(socket, ash_form: ash_form, forms: forms, page_title: "Account Settings")}
  end

  def handle_event("validate", %{"profile_form_id" => _profile_form_id}, socket) do
    # ash_form = AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, socket}
  end

  def handle_event(
        "submit",
        %{"profile_form_id" => profile_form_id},
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

    ash_form =
      %{
        "profile_form_id" => profile_form_id_setting.value
      }
      |> to_form()

    {:noreply, socket |> assign(ash_form: ash_form) |> put_flash(:info, "Successfully updated account settings.")}
  end
end
