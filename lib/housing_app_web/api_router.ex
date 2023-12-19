defmodule HousingAppWeb.Api.Router do
  use AshJsonApi.Api.Router,
    apis: [HousingApp.Management],
    json_schema: "/json_schema",
    open_api: "/open_api"
end
