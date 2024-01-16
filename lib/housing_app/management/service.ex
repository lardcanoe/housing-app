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

  def profile_meets_application_conditions?(profile, application, actor: actor, tenant: tenant) do
    Enum.all?(application.conditions, fn condition ->
      condition = HousingApp.Management.load!(condition, :common_query, actor: actor, tenant: tenant)

      HousingApp.Management.Profile
      |> match_resource(profile.id, condition.common_query, actor: actor, tenant: tenant)
      |> tap(fn x -> IO.inspect(x, label: "App '#{application.name}', CQ '#{condition.common_query.name}'") end)
    end)
  end

  def match_resource(resource, id, common_query, actor: actor, tenant: tenant) do
    # .exists?() has a bug that queries wrong

    resource
    |> Ash.Query.for_read(:match_by_id, %{id: id}, actor: actor, tenant: tenant, authorize?: false)
    |> filter_to_fragments(common_query.filter)
    |> HousingApp.Management.read!()
    |> Enum.any?()
  end

  def filter_resource(resource, read_action, nil, actor: actor, tenant: tenant) do
    resource
    |> Ash.Query.for_read(read_action, %{}, actor: actor, tenant: tenant)
    |> HousingApp.Management.read!()
  end

  # TODO: Should only do filter_to_fragments for profile data field
  def filter_resource(resource, read_action, common_query, actor: actor, tenant: tenant) do
    resource
    |> Ash.Query.for_read(read_action, %{}, actor: actor, tenant: tenant)
    |> filter_to_fragments(common_query.filter)
    |> HousingApp.Management.read!()
  end

  defp filter_to_fragments(query, %{"and" => %{} = predicate_map}) do
    frags =
      Enum.map(predicate_map, fn {k, v} ->
        create_fragment(k, v)
      end)

    Ash.Query.do_filter(query, frags)
  end

  defp create_fragment(field, value) when is_binary(value) do
    {:ok, frag} = AshPostgres.Functions.Fragment.casted_new(["data->>? = ?", field, value])
    frag
  end
end
