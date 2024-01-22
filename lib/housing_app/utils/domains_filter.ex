# defmodule HousingApp.Utils.DomainsFilterMiddleware do
#   @moduledoc """
#   Filters out requests which are going outside of the crawled domain.

#   The domain that is used to compare against the request url is obtained from the spider's `c:Crawly.Spider.base_url` callback.

#   Does not accept any options. Tuple-based configuration options will be ignored.

#   ### Example Declaration
#   ```
#   middlewares: [
#     Crawly.Middlewares.DomainFilter
#   ]
#   ```
#   """

#   @behaviour Crawly.Pipeline

#   require Logger

#   def run(request, state, _opts \\ [])

#   def run(request, %{spider_name: spider_name} = state, _opts) do
#     base_urls = spider_name.base_urls()

#     if String.starts_with?(request.url, base_urls) do
#       {request, state}
#     else
#       Logger.debug("Dropping request: #{inspect(request.url)} (domains filter)")

#       {false, state}
#     end
#   end

#   def run(request, state, _opts) do
#     {request, state}
#   end
# end
