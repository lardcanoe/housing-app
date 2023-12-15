defmodule HousingApp.Management do
  @moduledoc """
  The Management context for Profiles.
  """
  require Ash.Query

  use Ash.Api,
    otp_app: :housing_app,
    extensions: [AshAdmin.Api]

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
    case HousingApp.Management.TenantSetting.get_setting(:system, :profile_form_id,
           actor: current_user_tenant,
           tenant: tenant,
           not_found_error?: false
         ) do
      {:ok, setting} ->
        HousingApp.Management.Form.get_by_id(setting.value, actor: current_user_tenant, tenant: tenant)

      _ ->
        {:error, nil}
    end
  end

  def create_profile(attrs, tenant_id, opts \\ []) do
    attrs = Enum.into(attrs, %{"tenant_id" => tenant_id})

    HousingApp.Management.Profile
    |> Ash.Changeset.for_create(:create, attrs, opts)
    |> Ash.Changeset.set_tenant("tenant_" <> tenant_id)
    |> HousingApp.Management.create()
  end

  def list_profiles(tenant_id, opts \\ []) do
    HousingApp.Management.Profile
    |> Ash.Query.filter(tenant_id == ^tenant_id)
    |> Ash.Query.set_actor(opts)
    |> Ash.Query.set_tenant("tenant_" <> tenant_id)
    |> HousingApp.Management.read!()
  end

  def get_profile!(id, tenant_id, opts \\ []) do
    HousingApp.Management.Profile
    |> Ash.Query.filter(id == ^id and tenant_id == ^tenant_id)
    |> Ash.Query.set_actor(opts)
    |> Ash.Query.set_tenant("tenant_" <> tenant_id)
    |> HousingApp.Management.read_one!()
  end

  def get_application!(id, tenant_id, opts \\ []) do
    HousingApp.Management.Application
    |> Ash.Query.filter(id == ^id and tenant_id == ^tenant_id)
    |> Ash.Query.set_actor(opts)
    |> Ash.Query.set_tenant("tenant_" <> tenant_id)
    |> HousingApp.Management.read_one!()
  end

  def list_applications!(tenant_id, opts \\ []) do
    HousingApp.Management.Application
    |> Ash.Query.filter(tenant_id == ^tenant_id)
    |> Ash.Query.set_actor(opts)
    |> Ash.Query.set_tenant("tenant_" <> tenant_id)
    |> HousingApp.Management.read!()
  end
end
