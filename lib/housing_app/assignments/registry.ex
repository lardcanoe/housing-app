defmodule HousingApp.Assignments.Registry do
  @moduledoc false

  use Ash.Registry

  entries do
    entry HousingApp.Assignments.Building
    entry HousingApp.Assignments.Room
    entry HousingApp.Assignments.Bed
    entry HousingApp.Assignments.Booking
    entry HousingApp.Assignments.RoommateGroup
    entry HousingApp.Assignments.Roommate
    entry HousingApp.Assignments.RoommateInvite
    entry HousingApp.Assignments.RoleQuery
    entry HousingApp.Assignments.InventoryCriteria
  end
end
