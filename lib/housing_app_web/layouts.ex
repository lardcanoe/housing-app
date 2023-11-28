defmodule HousingAppWeb.Layouts do
  use HousingAppWeb, :html

  import HousingAppWeb.Components.Navbar
  import HousingAppWeb.Components.Sidebar

  embed_templates "layouts/*"
end
