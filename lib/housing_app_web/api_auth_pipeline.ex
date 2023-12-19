defmodule HousingAppWeb.ApiAuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :housing_app,
    error_handler: HousingAppWeb.AuthErrorHandler,
    module: HousingAppWeb.Guardian

  plug Guardian.Plug.VerifyHeader, claims: %{typ: "access"}, key: :current_user_tenant
  plug Guardian.Plug.LoadResource, key: :current_user_tenant
  plug :set_actor, :guardian_current_user_tenant_resource

  def set_actor(conn, key) do
    actor =
      conn
      |> Map.get(:private, %{})
      |> Map.get(key)

    conn
    |> Ash.PlugHelpers.set_actor(actor)
    |> Ash.PlugHelpers.set_tenant("tenant_" <> actor.tenant_id)
  end
end
