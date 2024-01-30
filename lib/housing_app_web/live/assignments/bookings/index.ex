defmodule HousingAppWeb.Live.Assignments.Bookings.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingAppWeb.Components.DataGrid

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Bookings"
      count={@count}
      loading={@loading}
      drawer={HousingAppWeb.Components.Drawer.Booking}
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
        <.link navigate={~p"/assignments/bookings/new"}>
          <button
            type="button"
            class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add booking
          </button>
        </.link>
      </:actions>
    </.data_grid>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(query_id: nil, loading: true, count: 0, sidebar: :residents, page_title: "Bookings")
     |> load_async_assigns()}
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
        |> Enum.filter(&(&1.resource == :booking))

      {:ok, %{queries: [%{id: nil, name: "Default"}] ++ queries}}
    end)
  end

  def handle_event("view-row", %{"id" => id}, socket) do
    send_update(HousingAppWeb.Components.Drawer.Booking, id: "drawer-right", booking_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/assignments/bookings/#{id}/edit")}
  end

  def handle_event("change-query", params, socket) do
    {:noreply, HousingAppWeb.Components.FilteredResource.handle_change_query(socket, params)}
  end

  def handle_event("filter-changed", %{"filter" => filter}, socket) do
    {:noreply, push_patch(socket, to: ~p"/assignments/bookings?filter=#{filter |> Jason.encode!() |> URI.encode()}")}
  end

  def handle_event("load-data", %{}, socket) do
    res = load_data(socket)

    {:reply, res, assign(socket, loading: false, count: length(res.data))}
  end

  defp load_data(socket) do
    %{
      columns: load_columns(socket),
      data: load_bookings(socket),
      filter: socket.assigns.filter
    }
  end

  defp load_bookings(socket) do
    socket
    |> filter_bookings()
    |> Enum.sort_by(& &1.profile.user_tenant.user.name)
    |> Enum.map(fn b ->
      %{
        "id" => b.id,
        "profile" => b.profile.user_tenant.user.name,
        "building" => b.bed.room.building.name,
        "room" => b.bed.room.name,
        "bed" => b.bed.name,
        "rate" => "#{b.product.name} ($#{b.product.rate})",
        "submission" => b.application_submission_id || "",
        "submission_link" =>
          if(b.application_submission_id,
            do: ~p"/applications/#{b.application_submission.application_id}/submissions/#{b.application_submission_id}",
            else: ""
          ),
        "start_at" => b.start_at,
        "end_at" => b.end_at,
        "data" => b.data,
        "actions" => [["Edit"], ["View"]]
      }
    end)
  end

  defp filter_bookings(%{assigns: %{query_id: query_id, queries: %{ok?: true, result: queries}}} = socket)
       when not is_nil(query_id) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    query = Enum.find(queries, &(&1.id == query_id))

    HousingApp.Assignments.Service.filter_resource(HousingApp.Assignments.Booking, :list, query,
      actor: current_user_tenant,
      tenant: tenant
    )
  end

  defp filter_bookings(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns
    HousingApp.Assignments.Booking.list!(actor: current_user_tenant, tenant: tenant)
  end

  # Reload as needed instead of keeping in memory during life cycle of page
  defp load_columns(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    form_columns =
      case HousingApp.Management.Service.get_booking_form(actor: current_user_tenant, tenant: tenant) do
        {:ok, form} ->
          form.json_schema
          |> Jason.decode!()
          |> HousingApp.Utils.JsonSchema.schema_to_aggrid_columns("data.")

        _ ->
          []
      end

    [
      %{field: "profile", minWidth: 160, pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
      %{field: "id", minWidth: 120, pinned: "left", hide: true},
      %{field: "building"},
      %{field: "room"},
      %{field: "bed"},
      %{field: "rate"},
      %{field: "start_at", headerName: "Start", type: "dateColumn"},
      %{field: "end_at", headerName: "End", type: "dateColumn"},
      %{field: "submission", headerName: "Submission", cellRenderer: "link"}
    ] ++
      form_columns ++
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
end
