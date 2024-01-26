defmodule HousingAppWeb.Router do
  use HousingAppWeb, :router
  use AshAuthentication.Phoenix.Router

  import AshAdmin.Router
  import HousingAppWeb.Gettext

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
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug HousingAppWeb.Api.AuthPipeline
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

      scope "/applications", Live.Applications do
        live "/", Index, :index
        live "/new", Edit, :new
        live "/:id/edit", Edit, :edit
        live "/:id", Submit, :submit
        live "/:id/submissions", Submissions, :submissions
      end

      scope "/accounting", Live.Accounting do
        scope "/products", Products do
          live "/", Index, :index
          live "/new", New, :new
          live "/:id/edit", Edit, :edit
        end
      end

      scope "/forms", Live.Forms do
        # TODO: pipe_through [:require_authenticated_non_end_user]

        live "/", Index, :index
        live "/new", Edit, :new
        live "/:id/edit", Edit, :edit
        live "/:id", View, :view
        live "/:id/submissions", Submissions, :submissions
      end

      scope "/profiles", Live.Profiles do
        # TODO: pipe_through [:require_authenticated_non_end_user]
        live "/", Index, :index
        live "/new", New, :new
        live "/:id", View, :view
        live "/:id/edit", Edit, :edit
      end

      scope "/assignments", Live.Assignments do
        # TODO: pipe_through [:require_authenticated_non_end_user]
        scope "/buildings", Buildings do
          live "/", Index, :index
          live "/new", New, :new
          # live "/:id", View, :view
          live "/:id/edit", Edit, :edit
        end

        scope "/rooms", Rooms do
          live "/", Index, :index
          live "/new", Edit, :new
          live "/:id", Index, :view
          live "/:id/edit", Edit, :edit
        end

        scope "/beds", Beds do
          live "/", Index, :index
          live "/new", New, :new
          live "/:id", Index, :view
          live "/:id/edit", Edit, :edit
        end

        scope "/bookings", Bookings do
          live "/", Index, :index
          live "/new", Form, :new
          live "/:id", Index, :view
          live "/:id/edit", Form, :edit
        end

        scope "/criteria", Criteria do
          live "/", Index, :index
          live "/new", Form, :new
          live "/:id/edit", Form, :edit
        end

        scope "/roommates", Roommates do
          live "/", Index, :index
        end

        scope "/roles", Roles do
          live "/staff", Index, :staff_index
          live "/students", Index, :student_index
          live "/ra", View, :role_ra
          live "/housing-director", View, :role_housing_director
          live "/new", Form, :new
          live "/:id/edit", Form, :edit
        end
      end

      scope "/notifications", Live.Notifications do
        live "/", Index, :index
      end

      scope "/reporting", Live.Reporting do
        # TODO: pipe_through [:require_authenticated_non_end_user]
        live "/", Index, :index
      end

      scope "/roommates", Live.Assignments.Roommates do
        live "/", User, :index
        live "/new", New, :new
      end

      scope "/settings", Live.Settings do
        live "/profile", UserSettings, :index
        live "/account", TenantSettings, :index
      end
    end
  end

  # https://hexdocs.pm/ash_json_api/open-api.html#use-with-phoenix
  scope "/api" do
    pipe_through :api

    # FUTURE: The problem is that "/api/open_api" is locked down below
    #         So even though these are public, the open_api is not
    forward "/swaggerui",
            OpenApiSpex.Plug.SwaggerUI,
            path: "/api/open_api",
            title: "Housing App - Swagger UI",
            default_model_expand_depth: 4

    forward "/redoc",
            Redoc.Plug.RedocUI,
            spec_url: "/api/open_api"
  end

  scope "/api" do
    pipe_through :api_auth

    # https://hexdocs.pm/ash_json_api/getting-started-with-json-api.html#add-the-routes-from-your-api-module-s
    forward "/", HousingAppWeb.Api.Router
  end

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

  def require_authenticated_non_end_user(conn, _opts) do
    # current_user_tenant isn't available?
    if is_nil(conn.assigns[:current_user_tenant]) || conn.assigns[:current_user_tenant].user_type == :user do
      conn
      |> put_flash(:error, dgettext("auth", "You are not authorized to access this page."))
      |> redirect(to: "/")
      |> halt()
    else
      conn
    end
  end
end
