defmodule HousingApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HousingAppWeb.Telemetry,
      HousingApp.Repo,
      {DNSCluster, query: Application.get_env(:housing_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HousingApp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: HousingApp.Finch},
      # Start a worker by calling: HousingApp.Worker.start_link(arg)
      # {HousingApp.Worker, arg},
      # Start to serve requests, typically the last entry
      HousingAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HousingApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HousingAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
