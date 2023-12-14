defmodule HousingAppWeb.Live.Reporting.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Reporting"
      count={@count}
      loading={@loading}
      current_user_tenant={@current_user_tenant}
    >
    </.data_grid>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0, loading: true, sidebar: :reporting, page_title: "Reporting Dashboard")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
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
     }, assign(socket, loading: false, count: 3)}
  end
end
