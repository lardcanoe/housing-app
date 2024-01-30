defmodule HousingAppWeb.Components.FilteredResource do
  @moduledoc false

  def handle_change_query(%{assigns: %{query_id: nil}} = socket, %{"query-id" => "default"}) do
    socket
  end

  def handle_change_query(socket, %{"query-id" => "default"}) do
    socket |> Phoenix.Component.assign(query_id: nil) |> Phoenix.LiveView.push_event("ag-grid:refresh", %{})
  end

  def handle_change_query(%{assigns: %{query_id: query_id}} = socket, %{"query-id" => value}) when query_id == value do
    socket
  end

  def handle_change_query(socket, %{"query-id" => value}) do
    socket |> Phoenix.Component.assign(query_id: value) |> Phoenix.LiveView.push_event("ag-grid:refresh", %{})
  end
end
