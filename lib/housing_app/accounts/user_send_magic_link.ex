defmodule HousingApp.Accounts.User.Senders.SendMagicLink do
  @moduledoc """
  Sends a magic link email
  """
  use AshAuthentication.Sender
  use HousingAppWeb, :verified_routes

  @impl AshAuthentication.Sender
  def send(user, token, _) do
    HousingApp.Accounts.Emails.deliver_magic_link(
      user,
      url(~p"/auth/user/magic_link/?token=#{token}")
    )
  end
end
