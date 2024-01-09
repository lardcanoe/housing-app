defmodule HousingApp.Management.Service do
  @moduledoc false

  def new_notification(subject, message, correlation, actor: actor, tenant: tenant) do
    HousingApp.Management.Notification
    |> Ash.Changeset.for_create(
      :create,
      %{
        subject: subject,
        message: message,
        correlation: correlation,
        user_tenant_id: actor.id,
        tenant_id: actor.tenant_id
      },
      actor: actor,
      tenant: tenant
    )
    |> HousingApp.Management.create()
  end

  def get_profile_form(actor: current_user_tenant, tenant: tenant) do
    get_form_for(:system, :profile_form_id, actor: current_user_tenant, tenant: tenant)
  end

  def get_building_form(actor: current_user_tenant, tenant: tenant) do
    get_form_for(:system, :building_form_id, actor: current_user_tenant, tenant: tenant)
  end

  def get_room_form(actor: current_user_tenant, tenant: tenant) do
    get_form_for(:system, :room_form_id, actor: current_user_tenant, tenant: tenant)
  end

  def get_bed_form(actor: current_user_tenant, tenant: tenant) do
    get_form_for(:system, :bed_form_id, actor: current_user_tenant, tenant: tenant)
  end

  def get_booking_form(actor: current_user_tenant, tenant: tenant) do
    get_form_for(:system, :booking_form_id, actor: current_user_tenant, tenant: tenant)
  end

  defp get_form_for(namespace, setting, actor: current_user_tenant, tenant: tenant) do
    case HousingApp.Management.TenantSetting.get_setting(namespace, setting,
           actor: current_user_tenant,
           tenant: tenant,
           not_found_error?: false
         ) do
      {:ok, %{} = setting} ->
        HousingApp.Management.Form.get_by_id(setting.value, actor: current_user_tenant, tenant: tenant)

      _ ->
        {:error, nil}
    end
  end

  def profile_meets_application_conditions?(_profile, application, actor: actor, tenant: tenant) do
    Enum.all?(application.conditions, fn condition ->
      _condition = HousingApp.Management.load!(condition, :common_query, actor: actor, tenant: tenant)
      true
    end)
  end
end
