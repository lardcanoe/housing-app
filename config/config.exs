# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# https://dev.to/talk2megooseman/using-phoenix-channels-high-memory-usage-save-money-with-erlfullsweepafter-3edl
:erlang.system_flag(:fullsweep_after, 20)

config :housing_app,
  ecto_repos: [HousingApp.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :housing_app, HousingAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: HousingAppWeb.ErrorHTML, json: HousingAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HousingApp.PubSub,
  live_view: [signing_salt: "juxpC4kA"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :housing_app, HousingApp.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2020 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :remote_ip]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :housing_app,
  ash_apis: [
    HousingApp.Accounts,
    HousingApp.Management,
    HousingApp.Assignments,
    HousingApp.Accounting
  ]

# https://hexdocs.pm/ash/policies.html#logging
config :ash, :policies, log_policy_breakdowns: :error

# https://hexdocs.pm/ash_json_api/getting-started-with-json-api.html#accept-json_api-content-type
config :mime, :types, %{"application/vnd.api+json" => ["json"]}

config :mime, :extensions, %{"json" => "application/vnd.api+json"}

config :spark, :formatter,
  remove_parens?: true,
  "Ash.Resource": [
    type: Ash.Resource,
    section_order: [
      :authentication,
      :token,
      :attributes,
      :relationships,
      :policies,
      :postgres
    ]
  ]

config :ex_cldr,
  default_locale: "en",
  default_backend: HousingApp.Cldr

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
