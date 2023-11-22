defmodule HousingAppWeb.PowEmailConfirmationMail do
  use HousingAppWeb, :mail

  def email_confirmation(assigns) do
    %Pow.Phoenix.Mailer.Template{
      subject: "Confirm your email address",
      html: ~H"""
        <h3>Hi</h3>
        <p>Please use the following link to confirm your e-mail address:</p>
        <p><a href="<%= @url %>"><%= @url %></a></p>
        """,
      text: ~P"""
        Hi,
        
        Please use the following link to confirm your e-mail address:
        
        <%= @url %>
        """
    }
  end
end
