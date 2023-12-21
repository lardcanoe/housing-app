defmodule HousingAppWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in liveviews
  """

  import Phoenix.Component
  use HousingAppWeb, :verified_routes

  def on_mount(:live_user_optional, _params, %{"user" => user}, socket) do
    if user do
      {:cont, socket}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(
        :live_user_required,
        _params,
        %{"user" => user, "user_tenant_id" => user_tenant_id},
        %{assigns: %{current_user: current_user}} = socket
      )
      when is_binary(user) and not is_nil(current_user) do
    case HousingApp.Accounts.UserTenant.get_by_id(user_tenant_id, actor: current_user) do
      {:error, _} ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}

      {:ok, user_tenant} ->
        {:cont, socket |> mount_user_success(current_user, user_tenant)}
    end
  end

  def on_mount(:live_user_required, _params, %{"user" => user}, %{assigns: %{current_user: current_user}} = socket)
      when is_binary(user) do
    case HousingApp.Accounts.UserTenant.get_default(actor: current_user) do
      {:error, _} ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}

      {:ok, user_tenant} ->
        {:cont, socket |> mount_user_success(current_user, user_tenant)}
    end
  end

  def on_mount(:live_user_required, _params, %{"user" => user}, socket) when is_nil(user) do
    {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
  end

  def on_mount(:live_no_user, _params, %{"user" => user}, socket) when is_binary(user) do
    {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    {:cont, assign(socket, :current_user, nil)}
  end

  # Replicate assigns in lib/housing_app_web/controllers/auth_controller.ex
  # But do NOT copy them, perform our own database queries

  def mount_user_success(socket, current_user, user_tenant) do
    Ash.set_tenant("tenant_#{user_tenant.tenant_id}")

    available_user_tenants = HousingApp.Accounts.UserTenant.find_for_user!(actor: current_user)

    socket
    |> assign(:current_user_tenant, user_tenant)
    |> assign(:current_tenant, "tenant_#{user_tenant.tenant_id}")
    |> assign(:available_user_tenants, available_user_tenants)
  end
end
