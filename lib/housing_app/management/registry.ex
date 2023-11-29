defmodule HousingApp.Management.Registry do
  use Ash.Registry

  entries do
    entry HousingApp.Management.Profile
    entry HousingApp.Management.Application
  end
end
