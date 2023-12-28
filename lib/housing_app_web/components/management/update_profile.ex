defmodule HousingAppWeb.Components.Management.UpdateProfile do
  @moduledoc false

  use HousingAppWeb, :live_component

  # import HousingAppWeb.CoreComponents, only: [icon: 1]

  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true
  attr :data, :any, required: true

  def render(assigns) do
    ~H"""
    <div>
      <.json_form form={@form} json_schema={@json_schema} phx-target={@myself} button_text="Next" />
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(params, socket) do
    {:ok,
     socket
     |> assign(params)
     |> load_profile()
     |> load_form()}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", data, socket) do
    %{json_schema: json_schema, profile: profile, current_user_tenant: current_user_tenant, current_tenant: tenant} =
      socket.assigns

    cast_data = HousingApp.Utils.JsonSchema.cast_params(json_schema, data)
    ref_schema = ExJsonSchema.Schema.resolve(json_schema)

    with :ok <- ExJsonSchema.Validator.validate(ref_schema, cast_data),
         {:ok, updated_profile} <-
           HousingApp.Management.Profile.submit(profile, %{data: cast_data}, actor: current_user_tenant, tenant: tenant) do
      send(self(), {:component_submit, cast_data})
      {:noreply, assign(socket, profile: updated_profile)}
    else
      {:error, _errors} ->
        {:noreply, put_flash(socket, :error, "Errors present in form submission.")}
    end
  end

  defp load_profile(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Management.Profile.get_mine(actor: current_user_tenant, tenant: tenant) do
      {:ok, profile} ->
        assign(socket, profile: profile, form: to_form(profile.data, as: "profile"))

      {:error, %Ash.Error.Query.NotFound{}} ->
        {:ok, profile} =
          HousingApp.Management.Profile
          |> Ash.Changeset.for_create(
            :create,
            %{user_tenant_id: current_user_tenant.id, tenant_id: current_user_tenant.tenant_id},
            actor: current_user_tenant,
            tenant: tenant,
            authorize?: false
          )
          |> HousingApp.Management.create()

        assign(socket, profile: profile, form: to_form(profile.data, as: "profile"))
    end
  end

  defp load_form(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Management.get_profile_form(actor: current_user_tenant, tenant: tenant) do
      {:ok, profile_form} ->
        assign(socket, json_schema: Jason.decode!(profile_form.json_schema))

      {:error, _} ->
        socket
    end
  end
end
