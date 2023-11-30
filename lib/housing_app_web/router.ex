defmodule HousingAppWeb.Router do
  use HousingAppWeb, :router
  use AshAuthentication.Phoenix.Router

  import HousingAppWeb.Gettext
  import AshAdmin.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HousingAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
  end

  scope "/", HousingAppWeb do
    pipe_through :browser

    sign_in_route(
      register_path: "/register",
      on_mount: [{HousingAppWeb.LiveUserAuth, :live_no_user}]
    )

    reset_route(on_mount: [{HousingAppWeb.LiveUserAuth, :live_no_user}])

    auth_routes_for(HousingApp.Accounts.User, to: AuthController)

    # live "/login", AuthLive.Index, :login
    # live "/register", AuthLive.Index, :register

    ash_authentication_live_session :maybe_authenticated,
      on_mount: {HousingAppWeb.LiveUserAuth, :live_user_optional} do
      # live "/profile/:username", ProfileLive.Index, :profile
      # live "/article/:slug", ArticleLive.Index, :index
    end
  end

  scope "/" do
    pipe_through [:browser, :require_authenticated_platform_admin]

    ash_admin("/admin")
  end

  scope "/", HousingAppWeb do
    pipe_through [:browser, :require_authenticated_user]

    sign_out_route(AuthController)

    get "/switch-tenant/:tenant_id", AuthController, :switch_tenant

    ash_authentication_live_session :authentication_required,
      on_mount: {HousingAppWeb.LiveUserAuth, :live_user_required} do
      live "/", Live.HomeLive, :index
      live "/applications", Live.Applications.Index, :index
      live "/applications/:id/edit", Live.Applications.Edit, :edit
      live "/applications/new", Live.Applications.New, :new
      live "/settings/profile", Live.UserSettingsLive, :index
      live "/settings/account", Live.UserSettingsLive, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", RealworldWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HousingAppWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, dgettext("auth", "You must log in to access this page."))
      |> redirect(to: "/sign-in")
      |> halt()
    end
  end

  def require_authenticated_platform_admin(conn, _opts) do
    if conn.assigns[:current_user] && conn.assigns[:current_user].role == :platform_admin do
      conn
    else
      conn
      |> put_flash(:error, dgettext("auth", "You are not authorized to access this page."))
      |> redirect(to: "/sign-in")
      |> halt()
    end
  end
end
