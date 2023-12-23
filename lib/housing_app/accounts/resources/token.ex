defmodule HousingApp.Accounts.Token do
  @moduledoc false
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource]

  token do
    api HousingApp.Accounts
  end

  postgres do
    table "tokens"
    repo HousingApp.Repo
  end
end
