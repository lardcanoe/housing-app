defmodule HousingAppWeb.Live.Assignments.Criteria.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div class="relative overflow-hidden bg-white dark:bg-gray-900 sm:rounded-lg">
      <div class="flex flex-col md:flex-row items-center justify-between space-y-3 md:space-y-0 md:space-x-4 p-2">
        <div class="w-full flex items-center space-x-3">
          <h1 class="dark:text-white font-semibold">Inventory Criteria</h1>
          <div class="grow"></div>
          <.link navigate={~p"/assignments/criteria/new"}>
            <button
              type="button"
              class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
            >
              <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add Inventory Criteria
            </button>
          </.link>
        </div>
      </div>

      <div class="dashboard-area-height mt-2">
        <.table id="criteria-table" rows={@criteria} pagination={false} row_id={fn row -> "criteria-row-#{row.id}" end}>
          <:col :let={r} label="name">
            <%= r.name %>
          </:col>
          <:col :let={r} label="description">
            <%= r.description %>
          </:col>
          <:col :let={r} label="edit">
            <.link navigate={~p"/assignments/criteria/#{r.id}/edit"}>
              <.button type="button">
                Edit
              </.button>
            </.link>
          </:col>
        </.table>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    criteria =
      [actor: current_user_tenant, tenant: tenant]
      |> HousingApp.Assignments.InventoryCriteria.list!()
      |> Enum.sort_by(& &1.name)

    {:ok, assign(socket, criteria: criteria, sidebar: :assignments, page_title: "Criteria")}
  end
end
