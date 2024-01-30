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
      filter_changes={true}
    >
      <:actions>
        <.data_grid_quick_filter />
      </:actions>
      <:actions>
        <.common_query_filter queries={@queries} query_id={@query_id} />
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
           sidebar: :residents,
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

  def handle_params(%{"filter" => filter}, _uri, socket) do
    {:noreply, assign(socket, filter: filter |> URI.decode() |> Jason.decode!())}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, filter: nil)}
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

  def handle_event("change-query", params, socket) do
    {:noreply, HousingAppWeb.Components.FilteredResource.handle_change_query(socket, params)}
  end

  def handle_event("load-data", %{}, socket) do
    res = load_data(socket)

    {:reply, res, assign(socket, loading: false, count: length(res.data))}
  end

  def handle_event("filter-changed", %{"filter" => filter}, socket) do
    {:noreply, push_patch(socket, to: ~p"/profiles?filter=#{filter |> Jason.encode!() |> URI.encode()}")}
  end

  defp load_profiles(socket) do
    socket
    |> filter_profiles()
    |> Enum.sort_by(& &1.user_tenant.user.name)
    |> Enum.map(fn p ->
      Map.merge(
        p.sanitized_data,
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
      data: load_profiles(socket),
      filter: socket.assigns.filter
    }
  end
end
