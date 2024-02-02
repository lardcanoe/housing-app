defmodule HousingAppWeb.Live.Assignments.Process.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  require Ash.Query

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div class="relative overflow-hidden bg-white dark:bg-gray-900 sm:rounded-lg">
      <div class="flex flex-col md:flex-row items-center justify-between space-y-3 md:space-y-0 md:space-x-4 p-2">
        <div class="w-full flex items-center space-x-3">
          <h1 class="dark:text-white font-semibold">Selection Process</h1>
          <div class="grow"></div>
          <.link navigate={~p"/assignments/processes/new"}>
            <button
              type="button"
              class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
            >
              <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add Selection Process
            </button>
          </.link>
        </div>
      </div>

      <div :if={@processes.ok? && @processes.result} class="dashboard-area-height mt-2">
        <.table
          id="processes-table"
          rows={@processes.result}
          pagination={false}
          row_id={fn row -> "processes-row-#{row.id}" end}
        >
          <:col :let={r} label="name">
            <%= r.name %>
          </:col>
          <:col :let={r} label="description">
            <%= r.description %>
          </:col>
          <:col :let={r} label="">
            <div class="flex">
              <div class="grow" />
              <.link class="mr-4" navigate={~p"/assignments/processes/#{r.id}/edit"}>
                <.button type="button">
                  Edit
                </.button>
              </.link>
              <.button type="button" class="mr-4" phx-click="copy" phx-value-id={r.id}>
                Copy
              </.button>
              <.button type="delete" phx-click={show_modal("delete-modal-#{r.id}")}>
                Delete
              </.button>
              <.modal id={"delete-modal-#{r.id}"}>
                <h1 class="text-lg font-semibold leading-8 mb-4 text-zinc-800 dark:text-gray-100">
                  Delete <%= r.name %>?
                </h1>

                <.button
                  type="delete"
                  phx-click={
                    JS.push("delete", value: %{id: r.id})
                    |> hide_modal("delete-modal-#{r.id}")
                  }
                >
                  Delete
                </.button>
              </.modal>
            </div>
          </:col>
        </.table>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(sidebar: :assignments, page_title: "Selection Processes")
     |> load_async_assigns()}
  end

  defp load_async_assigns(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    assign_async(socket, [:processes], fn ->
      processes =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Assignments.SelectionProcess.list!()
        |> Enum.sort_by(& &1.name)

      {:ok, %{processes: processes}}
    end)
  end

  def handle_event("copy", %{"id" => id}, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    with {:get, {:ok, process}} <-
           {:get, HousingApp.Assignments.SelectionProcess.get_by_id(id, actor: current_user_tenant, tenant: tenant)},
         {:copy, {:ok, _copied}} <-
           {:copy, HousingApp.Assignments.SelectionProcess.copy(process, actor: current_user_tenant, tenant: tenant)} do
      {:noreply,
       socket
       |> put_flash(:info, "Copied process")
       |> load_async_assigns()}
    else
      {:copy, {:error, _}} ->
        {:noreply, put_flash(socket, :error, "Failed to copy")}

      {:get, {:error, _}} ->
        {:noreply, put_flash(socket, :error, "Not found")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    HousingApp.Assignments.SelectionProcess
    |> Ash.Query.for_read(:read, actor: current_user_tenant, tenant: tenant)
    |> Ash.Query.filter(id == ^id and is_nil(archived_at))
    |> HousingApp.Assignments.read!()
    |> Enum.each(fn app ->
      app
      |> Ash.Changeset.for_destroy(:archive)
      |> HousingApp.Assignments.destroy!(actor: current_user_tenant, tenant: tenant)
    end)

    {:noreply,
     socket
     |> put_flash(:info, "Process deleted")
     |> load_async_assigns()}
  end
end
