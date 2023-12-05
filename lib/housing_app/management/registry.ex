defmodule HousingApp.Management.Registry do
  use Ash.Registry

  entries do
    entry HousingApp.Management.TenantSetting
    entry HousingApp.Management.Profile
    entry HousingApp.Management.Application
    entry HousingApp.Management.Form
    # entry HousingApp.Management.FormSubmission
  end
end
