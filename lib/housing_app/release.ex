defmodule HousingApp.Release do
  @moduledoc """
  Tasks that need to be executed in the released application (because mix is not present in releases).
  Copied from https://hexdocs.pm/ash_postgres/migrations_and_tasks.html
  """

  @app :housing_app

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  # only needed if you are using postgres multitenancy
  def migrate_tenants do
    load_app()

    for repo <- repos() do
      repo_name = repo |> Module.split() |> List.last() |> Macro.underscore()

      path =
        "priv/"
        |> Path.join(repo_name)
        |> Path.join("tenant_migrations")

      # This may be different for you if you are not using the default tenant migrations

      {:ok, _, _} =
        Ecto.Migrator.with_repo(
          repo,
          fn repo ->
            for tenant <- repo.all_tenants() do
              Ecto.Migrator.run(repo, path, :up, all: true, prefix: tenant)
            end
          end
        )
    end
  end

  # only needed if you are using postgres multitenancy
  def migrate_all do
    load_app()
    migrate()
    migrate_tenants()
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  # only needed if you are using postgres multitenancy
  def rollback_tenants(repo, version) do
    load_app()

    repo_name = repo |> Module.split() |> List.last() |> Macro.underscore()

    path =
      "priv/"
      |> Path.join(repo_name)
      |> Path.join("tenant_migrations")

    # This may be different for you if you are not using the default tenant migrations

    for tenant <- repo.all_tenants() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(
          repo,
          &Ecto.Migrator.run(&1, path, :down,
            to: version,
            prefix: tenant
          )
        )
    end
  end

  defp repos do
    apis()
    |> Enum.flat_map(fn api ->
      api
      |> Ash.Api.Info.resources()
      |> Enum.map(&AshPostgres.DataLayer.Info.repo/1)
    end)
    |> Enum.uniq()
  end

  defp apis do
    Application.fetch_env!(@app, :ash_apis)
  end

  defp load_app do
    Application.load(@app)
  end
end
