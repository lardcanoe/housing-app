# defmodule HousingApp.Utils.Crawl do
#   @moduledoc false
#   use Crawly.Spider

#   @impl Crawly.Spider
#   def base_url, do: ""

#   #     do: ["https://www.fisher.edu/", "https://www.msoe.edu/", "https://www.mtholyoke.edu/", "https://www.bsc.edu/"]

#   def base_urls,
#     do: [
#       "https://www.ab.edu/",
#       "https://www.sage.edu/",
#       "https://www.alma.edu/",
#       "https://www.indianatech.edu/",
#       "https://www.luther.edu/",
#       "https://www.misericordia.edu/",
#       "https://www.ouhsc.edu/",
#       "https://www.usiouxfalls.edu/",
#       "https://www.wvutech.edu/"
#     ]

#   @impl Crawly.Spider
#   def init do
#     [start_urls: HousingApp.Utils.Crawl.base_urls()]
#   end

#   def host_item_found(host) do
#     Process.put(host, true)
#   end

#   def is_host_found?(host) do
#     not is_nil(Process.get(host))
#   end

#   @impl Crawly.Spider
#   def parse_item(response) do
#     parsed_url = URI.parse(response.request.url)

#     if HousingApp.Utils.Crawl.is_host_found?(parsed_url.host) do
#       %{items: [], requests: []}
#     else
#       # Parse response body to document
#       case Floki.parse_document(response.body) do
#         {:ok, document} ->
#           # Create item (for pages where items exists)
#           urls =
#             document
#             |> Floki.find("a")
#             |> Floki.attribute("href")
#             |> Enum.reject(fn url ->
#               String.contains?(url, [
#                 "blog",
#                 "news",
#                 "about",
#                 "search",
#                 "events",
#                 "calendar",
#                 "academics",
#                 "faculty",
#                 "parents",
#                 "alums",
#                 "sports",
#                 "athletics"
#               ])
#             end)
#             |> Enum.map(fn url ->
#               url |> String.split("#") |> List.first() |> String.split("?") |> List.first()
#             end)
#             |> Enum.map(&Crawly.Utils.build_absolute_url(&1, response.request.url))
#             |> Enum.uniq()

#           items =
#             urls
#             |> Enum.filter(fn url ->
#               String.contains?(url, [
#                 "erezlife.com",
#                 "symplicity.com",
#                 "adirondacksolutions.com",
#                 "starrezhousing.com",
#                 "mycollegeroomie.com",
#                 "housing.cloud",
#                 "rms-inc.com"
#               ])
#             end)
#             |> Enum.map(fn url ->
#               HousingApp.Utils.Crawl.host_item_found(parsed_url.host)

#               %{
#                 host: parsed_url.host,
#                 tool: url_to_tool(url),
#                 portal: url,
#                 source: response.request.url
#               }
#             end)

#           if Enum.any?(items) do
#             # Stop once we find any
#             %{items: items, requests: []}
#           else
#             next_requests =
#               urls
#               |> Enum.filter(fn url ->
#                 String.contains?(url, ["res", "life", "hous", "student", "campus"]) and
#                   String.starts_with?(url, HousingApp.Utils.Crawl.base_urls())
#               end)
#               |> Enum.map(&Crawly.Utils.request_from_url/1)

#             %{items: items, requests: next_requests}
#           end

#         {:error, reason} ->
#           dbg(reason)
#           {:error, reason}
#       end
#     end
#   end

#   def url_to_tool(url) do
#     cond do
#       String.contains?(url, "erezlife.com") ->
#         "Erezlife"

#       String.contains?(url, "symplicity.com") ->
#         "Symplicity"

#       String.contains?(url, "adirondacksolutions.com") ->
#         "Adirondack Solutions"

#       String.contains?(url, "starrezhousing.com") ->
#         "StarRez"

#       String.contains?(url, "mycollegeroomie.com") ->
#         "MyCollegeRoomie"

#       String.contains?(url, "housing.cloud") ->
#         "Housing Cloud"

#       String.contains?(url, "rms-inc.com") ->
#         "RMS"

#       true ->
#         "Unknown"
#     end
#   end
# end
