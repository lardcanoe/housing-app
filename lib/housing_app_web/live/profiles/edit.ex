defmodule HousingAppWeb.Live.Profiles.Edit do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="bg-white dark:bg-white">
      <div id="json-schema-form" phx-hook="JSONSchemaForm" />
      <.button id="json-schema-form-submit" type="submit">
        Save
      </.button>
    </div>
    """
  end

  def mount(%{"id" => id}, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    case HousingApp.Management.Profile.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/profiles")}

      {:ok, profile} ->
        profile_form_id =
          case HousingApp.Management.TenantSetting.get_setting(:system, :profile_form_id,
                 actor: current_user_tenant,
                 tenant: tenant,
                 not_found_error?: false
               ) do
            {:ok, setting} -> setting.value
            _ -> nil
          end

        form = HousingApp.Management.Form.get_by_id!(profile_form_id, actor: current_user_tenant, tenant: tenant)

        {:ok, assign(socket, json_schema: form.json_schema |> Jason.decode!(), profile: profile, page_title: "Edit Profile")}
    end
  end

  def handle_event("load-schema", _params, socket) do
    {:reply, %{schema: socket.assigns.json_schema, data: socket.assigns.profile.data}, socket}
  end

  def handle_event("submit", data, socket) do
    ref_schema = ExJsonSchema.Schema.resolve(socket.assigns.json_schema)

    case ExJsonSchema.Validator.validate(ref_schema, data) do
      :ok ->
        socket.assigns.profile
        |> HousingApp.Management.Profile.submit(%{data: data}, actor: socket.assigns.current_user_tenant, tenant: socket.assigns.current_tenant)

        {:noreply,
         socket
         |> put_flash(:info, "Update profile")
         |> push_navigate(to: ~p"/profiles")}

      {:error, _errors} ->
        {:noreply, socket |> put_flash(:error, "Errors present in form submission.")}
    end
  end
end
