defmodule HousingAppWeb.PowResetPasswordMail do
  use HousingAppWeb, :mail

  def reset_password(assigns) do
    %Pow.Phoenix.Mailer.Template{
      subject: "Reset password link",
      html: ~H"""
        <h3>Hi,</h3>
        <p>Please use the following link to reset your password:</p>
        <p><a href="<%= @url %>"><%= @url %></a></p>
        <p>You can disregard this email if you didn't request a password reset.</p>
        """,
      text: ~P"""
        Hi,
        
        Please use the following link to reset your password:
        
        <%= @url %>
        
        You can disregard this email if you didn't request a password reset.
        """
    }
  end
end
