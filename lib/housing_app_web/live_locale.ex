defmodule HousingAppWeb.LiveLocale do
  @moduledoc false

  import Phoenix.Component

  @default_locale "en"
  @default_timezone "UTC"
  @default_timezone_offset 0

  def on_mount(:default, _params, _session, socket) do
    cp = Phoenix.LiveView.get_connect_params(socket)

    {:cont,
     socket
     |> assign(:locale, cp["locale"] || @default_locale)
     |> assign(:timezone, cp["timezone"] || @default_timezone)
     |> assign(:timezone_offset, cp["timezone_offset"] || @default_timezone_offset)}
  end
end
