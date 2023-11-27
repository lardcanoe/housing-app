defmodule HousingAppWeb.PageControllerTest do
  use HousingAppWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 302) ==
             "<html><body>You are being <a href=\"/sign-in\">redirected</a>.</body></html>"
  end
end
