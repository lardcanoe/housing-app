defmodule HousingAppWeb.Live.Assignments.Bookings.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

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
    >
      <:actions>
        <.link patch={~p"/assignments/bookings/new"}>
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
    {:ok, assign(socket, loading: true, count: 0, sidebar: :assignments, page_title: "Bookings")}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, loading: true, count: 0, sidebar: :assignments, page_title: "Bookings")}
  end

  def handle_event("view-row", %{"id" => id}, socket) do
    send_update(HousingAppWeb.Components.Drawer.Booking, id: "drawer-right", booking_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, socket |> push_navigate(to: ~p"/assignments/bookings/#{id}/edit")}
  end

  def handle_event(
        "load-data",
        %{},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    bookings =
      HousingApp.Assignments.Booking.list!(actor: current_user_tenant, tenant: tenant)
      |> Enum.sort_by(& &1.profile.user_tenant.user.name)
      |> Enum.map(fn b ->
        %{
          "id" => b.id,
          "profile" => b.profile.user_tenant.user.name,
          "building" => b.bed.room.building.name,
          "room" => b.bed.room.name,
          "bed" => b.bed.name,
          "rate" => "#{b.product.name} ($#{b.product.rate})",
          "start_at" => b.start_at,
          "end_at" => b.end_at,
          "data" => b.data,
          "actions" => [["Edit"], ["View"]]
        }
      end)

    form_columns =
      case HousingApp.Management.get_booking_form(actor: current_user_tenant, tenant: tenant) do
        {:ok, form} ->
          form.json_schema
          |> Jason.decode!()
          |> HousingApp.Utils.JsonSchema.schema_to_aggrid_columns("data.")

        _ ->
          []
      end

    columns =
      [
        %{field: "profile", minWidth: 160, pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
        %{field: "id", minWidth: 120, pinned: "left", hide: true},
        %{field: "building"},
        %{field: "room"},
        %{field: "bed"},
        %{field: "rate"},
        %{field: "start_at", headerName: "Start", type: "dateColumn"},
        %{field: "end_at", headerName: "End", type: "dateColumn"}
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

    {:reply,
     %{
       columns: columns,
       data: bookings
     }, assign(socket, loading: false, count: length(bookings))}
  end
end
