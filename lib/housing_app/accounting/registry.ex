defmodule HousingApp.Accounting.Registry do
  @moduledoc false

  use Ash.Registry

  entries do
    entry HousingApp.Accounting.Product
  end
end
