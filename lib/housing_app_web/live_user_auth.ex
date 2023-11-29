defmodule HousingAppWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in liveviews
  """

  import Phoenix.Component
  use HousingAppWeb, :verified_routes

  def on_mount(:live_user_optional, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:live_user_required, _params, _session, %{assigns: %{current_user: current_user}} = socket) when is_nil(current_user) do
    {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
  end

  def on_mount(:live_user_required, _params, _session, %{assigns: %{current_user: current_user}} = socket) do
    case HousingApp.Accounts.get_default_user_tenant_for!(current_user.id) do
      nil ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}

      user_tenant ->
        # Replicate assigns in lib/housing_app_web/controllers/auth_controller.ex

        Ash.set_tenant("tenant_#{user_tenant.tenant_id}")

        socket =
          socket
          |> assign(:current_user_tenant, user_tenant)
          |> assign(:current_tenant, "tenant_#{user_tenant.tenant_id}")

        {:cont, socket}
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end
end
