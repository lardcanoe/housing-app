defmodule HousingAppWeb.Layouts do
  @moduledoc false

  use HousingAppWeb, :html

  import HousingAppWeb.Components.Sidebar

  embed_templates "layouts/*"
end
