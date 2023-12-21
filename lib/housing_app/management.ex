defmodule HousingApp.Management do
  @moduledoc """
  The Management context for Profiles.
  """
  require Ash.Query

  use Ash.Api,
    otp_app: :housing_app,
    extensions: [AshAdmin.Api, AshJsonApi.Api]

  # https://hexdocs.pm/ash/dsl-ash-api.html#authorization
  # https://hexdocs.pm/ash/security.html#authorization-configuration
  authorization do
    authorize :by_default
  end

  admin do
    show?(true)
  end

  resources do
    registry HousingApp.Management.Registry
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
end
