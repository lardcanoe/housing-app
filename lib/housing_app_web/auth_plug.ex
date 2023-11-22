defmodule HousingAppWeb.AuthPlug do
  @moduledoc false

  use HousingAppWeb, :verified_routes

  import Phoenix.Controller
  import Plug.Conn
  import HousingAppWeb.Gettext

  @spec require_authenticated_user(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, dgettext("auth", "You must log in to access this page."))
      |> redirect(to: ~p"/session/new")
      |> halt()
    end
  end
end
