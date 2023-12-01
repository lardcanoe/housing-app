defmodule HousingAppWeb.AuthController do
  use HousingAppWeb, :controller
  use AshAuthentication.Phoenix.Controller

  # Replicate assigns in lib/housing_app_web/live_user_auth.ex

  def success(conn, _activity, user, _token) do
    case HousingApp.Accounts.UserTenant.get_default(actor: user) do
      {:error, _} ->
        conn
        |> clear_session()
        |> put_flash(:error, "You do not have access to any accounts.")
        |> redirect(to: ~p"/sign-in")

      {:ok, user_tenant} ->
        return_to = get_session(conn, :return_to) || ~p"/"

        Ash.set_tenant("tenant_#{user_tenant.tenant_id}")

        conn
        |> delete_session(:return_to)
        |> store_in_session(user)
        |> put_session(:user_tenant_id, user_tenant.id)
        |> assign(:current_user, user)
        |> assign(:current_user_tenant, user_tenant)
        |> redirect(to: return_to)
    end
  end

  def switch_tenant(conn, %{"tenant_id" => tenant_id}) do
    case HousingApp.Accounts.UserTenant.get_for_tenant(tenant_id, actor: conn.assigns[:current_user]) do
      {:error, _} ->
        conn
        |> redirect(to: ~p"/")

      {:ok, user_tenant} ->
        return_to = get_session(conn, :return_to) || ~p"/"

        Ash.set_tenant("tenant_#{user_tenant.tenant_id}")

        conn
        |> delete_session(:return_to)
        |> put_session(:user_tenant_id, user_tenant.id)
        |> assign(:current_user_tenant, user_tenant)
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
