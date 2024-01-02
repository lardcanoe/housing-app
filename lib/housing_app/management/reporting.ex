defmodule HousingApp.Management.Reporting do
  @moduledoc false

  def housing_application_submissions(actor: current_user_tenant, tenant: tenant) do
    HousingApp.Management.Application.list_by_type!("Housing", :approved, actor: current_user_tenant, tenant: tenant)
  end
end
