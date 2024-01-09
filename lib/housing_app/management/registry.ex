defmodule HousingApp.Management.Registry do
  @moduledoc false

  use Ash.Registry

  entries do
    entry HousingApp.Management.TenantSetting
    entry HousingApp.Management.TimePeriod
    entry HousingApp.Management.Profile
    entry HousingApp.Management.Application
    entry HousingApp.Management.ApplicationSubmission
    entry HousingApp.Management.ApplicationStepSubmission
    entry HousingApp.Management.Form
    entry HousingApp.Management.FormSubmission
    entry HousingApp.Management.Notification
    entry HousingApp.Management.CommonQuery
  end
end
