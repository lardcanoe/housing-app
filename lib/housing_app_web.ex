defmodule HousingAppWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use HousingAppWeb, :controller
      use HousingAppWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: true

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: HousingAppWeb.Layouts]

      import Plug.Conn
      import HousingAppWeb.Gettext
      alias HousingAppWeb.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  @doc false
  def view do
    quote do
      use Phoenix.View,
        # root: "lib/housing_app_web/components",
        root: "lib/housing_app_web/templates",
        namespace: HousingAppWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      use Phoenix.Component

      import Phoenix.View

      # Include shared imports and aliases for views
      unquote(html_helpers())
    end
  end

  def live_view(opts \\ []) do
    quote do
      @opts Keyword.merge(
              [
                layout: {HousingAppWeb.Layouts, :empty}
              ],
              unquote(opts)
            )
      use Phoenix.LiveView, @opts

      on_mount HousingAppWeb.LiveFlash

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      import HousingAppWeb.CoreComponents
      import HousingAppWeb.PlatformTypes
      import HousingAppWeb.Components.DataGrid
      import HousingAppWeb.Gettext

      alias Phoenix.LiveView.JS
      alias HousingAppWeb.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  # Routes generation with the ~p sigil
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: HousingAppWeb.Endpoint,
        router: HousingAppWeb.Router,
        statics: HousingAppWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__({which, opts}) when is_atom(which) do
    apply(__MODULE__, which, [opts])
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
