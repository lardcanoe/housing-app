defmodule HousingAppWeb.Live.Profiles.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingAppWeb.Components.DataGrid

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Profiles"
      count={@count}
      loading={@loading}
      drawer={HousingAppWeb.Components.Drawer.Profile}
      current_user_tenant={@current_user_tenant}
      current_tenant={@current_tenant}
    >
      <:actions>
        <input
          type="text"
          id="datagrid-quickfilter"
          class="block w-52 p-2.5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-primary-500 focus:border-primary-500 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-primary-500 dark:focus:border-primary-500"
          placeholder="Search"
        />
      </:actions>
      <:actions>
        <div class={["relative", not @queries.ok? or (length(@queries.result) <= 1 && "hidden")]}>
          <button
            type="button"
            id="dropdownQueries"
            data-dropdown-toggle="dropdownQueriesMenu"
            class="w-full md:w-auto flex items-center justify-center py-2 px-3 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-primary-700 focus:z-10 focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700"
          >
            <.icon name="hero-chevron-down-solid" class="w-4 h-4 mr-2" /> Apply Query
          </button>
          <!-- Dropdown menu -->
          <div
            id="dropdownQueriesMenu"
            class="hidden z-10 absolute list-none -translate-x-1/2 top-10 -left-32 w-48 bg-white divide-y divide-gray-100 rounded-lg dark:bg-gray-700 dark:divide-gray-600"
          >
            <ul class="p-3 space-y-3 text-sm text-gray-700 dark:text-gray-200" aria-labelledby="dropdownQueries">
              <%= if @queries.ok? && @queries.result do %>
                <li :for={q <- @queries.result}>
                  <div class="flex items-center" phx-click="change-query" phx-value-query-id={q.id || "default"}>
                    <input
                      id={"selected-query-#{q.id || "default"}"}
                      type="radio"
                      value={q.id}
                      name="selected-query"
                      class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-700 dark:focus:ring-offset-gray-700 focus:ring-2 dark:bg-gray-600 dark:border-gray-500"
                      {if(@query_id == q.id, do: [{"checked",""}], else: [])}
                    />
                    <label for="selected-query" class="ms-2 text-sm font-medium text-gray-900 dark:text-gray-300">
                      <%= q.name %>
                    </label>
                  </div>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
      </:actions>
      <:actions>
        <.link navigate={~p"/profiles/new"}>
          <button
            type="button"
            class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add profile
          </button>
        </.link>
      </:actions>
    </.data_grid>
    """
  end

  def mount(_params, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Management.Service.get_profile_form(actor: current_user_tenant, tenant: tenant) do
      {:ok, profile_form} ->
        {:ok,
         socket
         |> assign(
           query_id: nil,
           profile_form: profile_form,
           loading: true,
           count: 0,
           sidebar: :profiles,
           page_title: "Profiles"
         )
         |> load_async_assigns()}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Error loading profile form.")
         |> push_navigate(~p"/")}
    end
  end

  defp load_async_assigns(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    assign_async(socket, [:queries], fn ->
      queries =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Management.CommonQuery.list!()
        |> Enum.filter(&(&1.resource == :profile))

      {:ok, %{queries: [%{id: nil, name: "Default"}] ++ queries}}
    end)
  end

  def handle_event("view-row", %{"id" => id}, socket) do
    send_update(HousingAppWeb.Components.Drawer.Profile, id: "drawer-right", profile_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/profiles/#{id}/edit")}
  end

  def handle_event("change-query", %{"query-id" => "default"}, %{assigns: %{query_id: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_event("change-query", %{"query-id" => "default"}, socket) do
    {:noreply, socket |> assign(query_id: nil) |> push_event("ag-grid:refresh", %{})}
  end

  def handle_event("change-query", %{"query-id" => value}, %{assigns: %{query_id: query_id}} = socket)
      when query_id == value do
    {:noreply, socket}
  end

  def handle_event("change-query", %{"query-id" => value}, socket) do
    {:noreply, socket |> assign(query_id: value) |> push_event("ag-grid:refresh", %{})}
  end

  def handle_event("load-data", %{}, socket) do
    res = load_data(socket)

    {:reply, res, assign(socket, loading: false, count: length(res.data))}
  end

  defp load_profiles(socket) do
    socket
    |> filter_profiles()
    |> Enum.sort_by(& &1.user_tenant.user.name)
    |> Enum.map(fn p ->
      Map.merge(
        p.data,
        %{
          "id" => p.id,
          "user_name" => p.user_tenant.user.name,
          "user_email" => p.user_tenant.user.email,
          "actions" => [["Edit"], ["View"]]
        }
      )
    end)
  end

  defp filter_profiles(%{assigns: %{query_id: nil}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    HousingApp.Management.Profile.list!(actor: current_user_tenant, tenant: tenant)
  end

  defp filter_profiles(%{assigns: %{queries: %{ok?: false}}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns
    # TODO: Handle still loading?
    HousingApp.Management.Profile.list!(actor: current_user_tenant, tenant: tenant)
  end

  defp filter_profiles(%{assigns: %{query_id: query_id, queries: %{ok?: true, result: queries}}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    query = Enum.find(queries, &(&1.id == query_id))

    if query do
      HousingApp.Management.Service.filter_resource(HousingApp.Management.Profile, :list, query,
        actor: current_user_tenant,
        tenant: tenant
      )
    else
      # TODO: Not found
      HousingApp.Management.Profile.list!(actor: current_user_tenant, tenant: tenant)
    end
  end

  # Reload as needed instead of keeping in memory during life cycle of page
  defp load_columns(socket) do
    %{profile_form: profile_form} = socket.assigns

    schema = Jason.decode!(profile_form.json_schema)

    [
      %{
        field: "user_name",
        headerName: "User",
        minWidth: 220,
        pinned: "left",
        checkboxSelection: true,
        headerCheckboxSelection: true
      },
      %{field: "id", minWidth: 120, pinned: "left", hide: true},
      %{field: "user_email", headerName: "Email", minWidth: 250}
    ] ++
      HousingApp.Utils.JsonSchema.schema_to_aggrid_columns(schema) ++
      [
        %{
          field: "actions",
          pinned: "right",
          minWidth: 120,
          maxWidth: 120,
          filter: false,
          editable: false,
          sortable: false,
          resizable: false
        }
      ]
  end

  defp load_data(socket) do
    %{
      columns: load_columns(socket),
      data: load_profiles(socket)
    }
  end
end
