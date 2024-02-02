defmodule HousingAppWeb.Components.FilteredResource do
  @moduledoc false

  import Phoenix.Component
  import Phoenix.LiveView

  def handle_change_query(%{assigns: %{query_id: nil}} = socket, %{"query-id" => "default"}) do
    socket
  end

  def handle_change_query(socket, %{"query-id" => "default"}) do
    socket |> assign(query_id: nil) |> push_event("ag-grid:refresh", %{})
  end

  def handle_change_query(%{assigns: %{query_id: query_id}} = socket, %{"query-id" => value}) when query_id == value do
    socket
  end

  def handle_change_query(socket, %{"query-id" => value}) do
    socket |> assign(query_id: value) |> push_event("ag-grid:refresh", %{})
  end

  def handle_selection_changed(socket, %{"ids" => []}) do
    socket
    |> assign(selected_ids: [])
    |> push_event("js-exec", %{to: "#delete-button", attr: "data-empty"})
  end

  def handle_selection_changed(socket, %{"ids" => ids}) do
    socket
    |> assign(selected_ids: ids)
    |> push_event("js-exec", %{to: "#delete-button", attr: "data-selected"})
  end
end
