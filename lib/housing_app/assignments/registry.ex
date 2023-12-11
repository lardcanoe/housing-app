defmodule HousingApp.Assignments.Registry do
  @moduledoc false

  use Ash.Registry

  entries do
    entry HousingApp.Assignments.Building
    entry HousingApp.Assignments.Room
    entry HousingApp.Assignments.Bed
    entry HousingApp.Assignments.Booking
  end
end
