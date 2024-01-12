defmodule HousingAppWeb.PlatformTypes do
  @moduledoc """
  This module contains functions that are used to populate select options
  """

  @status_options [
    {"Draft", :draft},
    {"Approved (Published)", :approved},
    {"Archived", :archived}
  ]

  @submission_types [
    {"Once", :once},
    {"Many", :many}
  ]

  @user_types [
    {"Admin", :admin},
    {"Staff", :staff}
  ]

  @resource_options [
    {"Profile", :profile}
  ]

  @role_resource_options [
    {"Application", :application},
    {"Form", :form},
    {"Profile", :profile}
  ]

  @empty_option {"-- Select a default --", nil}

  def time_periods(actor, tenant) do
    HousingApp.Management.TimePeriod.list!(actor: actor, tenant: tenant)
  end

  def time_period_options(actor, tenant) do
    user_defined =
      actor
      |> time_periods(tenant)
      |> Enum.map(&{&1.name, &1.id})

    [@empty_option] ++ user_defined
  end

  def status_options, do: @status_options

  def submission_type_options, do: @submission_types

  def user_type_options, do: @user_types

  def resource_options, do: @resource_options

  def role_resource_options, do: @role_resource_options

  def all_forms(actor, tenant) do
    HousingApp.Management.Form.list!(actor: actor, tenant: tenant)
  end

  def all_form_options(actor, tenant) do
    actor
    |> all_forms(tenant)
    |> Enum.map(&{&1.name, &1.id})
  end

  def all_forms_with_empty(actor, tenant) do
    [@empty_option] ++ all_form_options(actor, tenant)
  end

  def approved_forms(actor, tenant) do
    HousingApp.Management.Form.list_approved!(actor: actor, tenant: tenant)
  end

  def approved_form_options(actor, tenant) do
    actor
    |> approved_forms(tenant)
    |> Enum.map(&{&1.name, &1.id})
  end

  def approved_forms_with_empty(actor, tenant) do
    [@empty_option] ++ approved_form_options(actor, tenant)
  end

  def management_form_for_create(resource, action, opts \\ []) do
    opts =
      Keyword.merge(
        [
          api: HousingApp.Management,
          forms: [auto?: true],
          as: "form"
        ],
        opts
      )

    resource
    |> AshPhoenix.Form.for_create(action, opts)
    |> Phoenix.Component.to_form()
  end

  def management_form_for_update(record, action, opts \\ []) do
    opts =
      Keyword.merge(
        [
          api: HousingApp.Management,
          forms: [auto?: true],
          as: "form"
        ],
        opts
      )

    record
    |> AshPhoenix.Form.for_update(action, opts)
    |> Phoenix.Component.to_form()
  end
end
