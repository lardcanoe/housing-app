defmodule HousingAppWeb.Live.Reporting.Index do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div id="myGrid" style="width: 100%; height: 400px;" class="ag-theme-quartz-dark" phx-hook="AgGrid"></div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Reporting Dashboard")}
  end

  def handle_event("load-data", %{}, socket) do
    {:reply,
     %{
       columns: [
         %{field: "make"},
         %{field: "model"},
         %{field: "price"}
       ],
       data: [
         %{make: "Toyota", model: "Corolla", price: 35000},
         %{make: "Ford", model: "Mondeo", price: 32000},
         %{make: "Porsche", model: "Boxter", price: 72000}
       ]
     }, socket}
  end
end