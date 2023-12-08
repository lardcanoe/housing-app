defmodule HousingAppWeb.Live.Reporting.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Reporting</h1>

    <div id="myGrid" style="width: 100%; height: 400px;" class="ag-theme-quartz-dark" phx-hook="AgGrid"></div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Reporting Dashboard")}
  end

  def handle_event("load-data", %{}, socket) do
    {:reply,
     %{
       columns: [%{field: "make"}, %{field: "model"}, %{field: "price"}],
       data: [
         %{make: "Toyota", model: "Corolla", price: 35_000},
         %{make: "Ford", model: "Mondeo", price: 32_000},
         %{make: "Porsche", model: "Boxter", price: 72_000}
       ]
     }, socket}
  end
end
