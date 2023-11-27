import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :housing_app, HousingApp.Repo,
  username: "elixir",
  password: "password",
  hostname: "localhost",
  database: "housing_app_test#{System.get_env("MIX_TEST_PARTITION")}",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :housing_app, HousingAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "dd6Bvbwn2XrQg+Ry0rJ6LXI+f0qKG2eujG1jNbTinp9nXjIbvuttkJbAk9s+gf1+",
  server: false

# In test we don't send emails.
config :housing_app, HousingApp.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :housing_app,
  token_signing_secret: "this-is-a-secret"
