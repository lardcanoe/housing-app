defmodule HousingAppWeb.AuthLive.Index do
  use HousingAppWeb, :live_view

  alias HousingApp.Accounts
  alias HousingApp.Accounts.User
  alias AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :register, _params) do
    socket
    |> assign(:form_id, "sign-up-form")
    |> assign(:cta, "Sign up")
    |> assign(:alternative, "Have an account?")
    |> assign(:alternative_path, Routes.auth_path(socket, :login))
    |> assign(:action, Routes.auth_path(socket, {:user, :password, :register}))
    |> assign(
      :form,
      Form.for_create(User, :register_with_password, api: Accounts, as: "user")
    )
  end

  defp apply_action(socket, :login, _params) do
    socket
    |> assign(:form_id, "sign-in-form")
    |> assign(:cta, "Sign in")
    |> assign(:alternative, "Need an account?")
    |> assign(:alternative_path, Routes.auth_path(socket, :register))
    |> assign(:action, Routes.auth_path(socket, {:user, :password, :sign_in}))
    |> assign(
      :form,
      Form.for_action(User, :sign_in_with_password, api: Accounts, as: "user")
    )
  end
end
