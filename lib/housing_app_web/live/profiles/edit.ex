defmodule HousingAppWeb.Live.Profiles.Edit do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <.json_form form={@form} json_schema={@json_schema} />
    """
  end

  def mount(
        %{"id" => id},
        _session,
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    with {:ok, profile} <- HousingApp.Management.Profile.get_by_id(id, actor: current_user_tenant, tenant: tenant),
         {:ok, profile_form} <- HousingApp.Management.get_profile_form(actor: current_user_tenant, tenant: tenant) do
      {:ok,
       assign(socket,
         json_schema: profile_form.json_schema |> Jason.decode!(),
         profile: profile,
         form: profile.data |> to_form(as: "profile"),
         sidebar: :profiles,
         page_title: "Edit Profile"
       )}
    else
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :profiles)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/profiles")}
    end
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "submit",
        data,
        %{
          assigns: %{
            json_schema: json_schema,
            profile: profile,
            current_user_tenant: current_user_tenant,
            current_tenant: tenant
          }
        } = socket
      ) do
    data = HousingApp.Utils.JsonSchema.cast_params(json_schema, data)

    ref_schema = ExJsonSchema.Schema.resolve(json_schema)

    case ExJsonSchema.Validator.validate(ref_schema, data) do
      :ok ->
        profile
        |> HousingApp.Management.Profile.submit(%{data: data},
          actor: current_user_tenant,
          tenant: tenant
        )

        {:noreply,
         socket
         |> put_flash(:info, "Update profile")
         |> push_navigate(to: ~p"/profiles")}

      {:error, _errors} ->
        {:noreply, socket |> put_flash(:error, "Errors present in form submission.")}
    end
  end
end
