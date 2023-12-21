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

  @empty_option {"-- Select a default --", nil}

  def time_periods(actor, tenant) do
    HousingApp.Management.TimePeriod.list!(actor: actor, tenant: tenant)
  end

  def time_period_options(actor, tenant) do
    user_defined =
      time_periods(actor, tenant)
      |> Enum.map(&{&1.name, &1.id})

    [@empty_option] ++ user_defined
  end

  def status_options, do: @status_options

  def submission_type_options, do: @submission_types

  def all_forms(actor, tenant) do
    HousingApp.Management.Form.list!(actor: actor, tenant: tenant)
  end

  def all_form_options(actor, tenant) do
    all_forms(actor, tenant)
    |> Enum.map(&{&1.name, &1.id})
  end

  def all_forms_with_empty(actor, tenant) do
    [@empty_option] ++ all_form_options(actor, tenant)
  end

  def approved_forms(actor, tenant) do
    HousingApp.Management.Form.list_approved!(actor: actor, tenant: tenant)
  end

  def approved_form_options(actor, tenant) do
    approved_forms(actor, tenant)
    |> Enum.map(&{&1.name, &1.id})
  end

  def approved_forms_with_empty(actor, tenant) do
    [@empty_option] ++ approved_form_options(actor, tenant)
  end

  def new_management_ash_form(resource, actor, tenant) do
    AshPhoenix.Form.for_create(resource, :new,
      api: HousingApp.Management,
      forms: [auto?: true],
      actor: actor,
      tenant: tenant
    )
    |> Phoenix.Component.to_form()
  end
end
