defmodule HousingAppWeb.LiveHelpers do
  @moduledoc false

  import Phoenix.Component

  alias HousingApp.Accounts
  alias HousingApp.Accounts.User

  def assign_defaults(%{"user" => "user?id=" <> user_id}, socket) do
    current_user = User |> Accounts.get!(user_id)

    socket
    |> assign(current_user: current_user)
  end

  def assign_defaults(_session, socket) do
    socket
    |> assign(current_user: nil)
  end
end
