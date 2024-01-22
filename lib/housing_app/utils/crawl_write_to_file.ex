# defmodule HousingApp.Utils.CrawlWriteToFile do
#   @moduledoc false
#   @behaviour Crawly.Pipeline

#   require Logger

#   @impl Crawly.Pipeline
#   @spec run(
#           item :: any,
#           state :: %{
#             optional(:write_to_file_fd) => pid | {:file_descriptor, atom, any}
#           },
#           opts :: [
#             folder: String.t(),
#             extension: String.t(),
#             include_timestamp: boolean()
#           ]
#         ) ::
#           {item :: any, state :: %{write_to_file_fd: pid | {:file_descriptor, atom, any}}}
#   def run(item, state, opts \\ [])

#   def run(item, %{write_to_file_fd: fd} = state, _opts) do
#     :ok = write(fd, item)
#     {item, state}
#   end

#   # No active FD
#   def run(item, state, opts) do
#     fd = opts |> Keyword.get(:filename, "./crawl.csv") |> open_fd()
#     :ok = write(fd, item)
#     {item, Map.put(state, :write_to_file_fd, fd)}
#   end

#   defp open_fd(filename) do
#     # Open file descriptor to write items
#     {:ok, io_device} =
#       File.open(
#         filename,
#         [:binary, :append, :delayed_write, :utf8]
#       )

#     io_device
#   end

#   # Performs the write operation
#   @spec write(io, item) :: :ok
#         when io: File.io_device(),
#              item: any()
#   defp write(io, item) do
#     IO.write(io, item)
#     IO.write(io, "\n")
#   catch
#     error, reason ->
#       Logger.error(
#         "Could not write item: #{inspect(item)} to io: #{inspect(io)}\n#{Exception.format(error, reason, __STACKTRACE__)}"
#       )
#   end
# end
