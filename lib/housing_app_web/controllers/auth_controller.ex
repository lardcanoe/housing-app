defmodule HousingAppWeb.AuthController do
  use HousingAppWeb, :controller
  use AshAuthentication.Phoenix.Controller

  # Replicate assigns in lib/housing_app_web/live_user_auth.ex

  def success(conn, _activity, user, _token) do
    case HousingApp.Accounts.get_default_user_tenant_for!(user.id) do
      nil ->
        conn
        |> clear_session()
        |> redirect(to: ~p"/sign-in")

      user_tenant ->
        return_to = get_session(conn, :return_to) || ~p"/"

        Ash.set_tenant("tenant_#{user_tenant.tenant_id}")

        conn
        |> delete_session(:return_to)
        |> store_in_session(user)
        |> assign(:current_user, user)
        |> redirect(to: return_to)
    end
  end

  def failure(conn, _activity, _reason) do
    conn
    |> put_status(401)
    |> render("failure.html")
  end

  def sign_out(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: ~p"/sign-in")
  end
end
