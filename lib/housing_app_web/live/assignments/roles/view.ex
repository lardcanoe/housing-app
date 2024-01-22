defmodule HousingAppWeb.Live.Assignments.Roles.View do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">RA Assignments</h1>

    <.table
      :if={@bookings.ok? && @bookings.result}
      id="bookings"
      rows={@bookings.result}
      pagination={false}
      row_id={fn row -> "bookings-row-#{row.id}" end}
    >
      <:col :let={booking} label="name">
        <%= booking.profile.user_tenant.user.name %>
      </:col>
      <:col :let={booking} label="building">
        <%= booking.bed.room.building.name %>
      </:col>
      <:col :let={booking} label="room">
        <%= booking.bed.room.name %>
      </:col>
      <:col :let={booking} label="bed">
        <%= booking.bed.name %>
      </:col>
    </.table>
    """
  end

  def mount(_params, _session, %{assigns: %{live_action: :role_ra}} = socket) do
    %{current_roles: current_roles} = socket.assigns

    if Enum.any?(current_roles, &(&1.name == "RA")) do
      {:ok, load_async_assigns(socket)}
    else
      {:ok, push_navigate(socket, to: ~p"/")}
    end
  end

  defp load_async_assigns(socket) do
    if connected?(socket) do
      load_async_connected_assigns(socket)
    else
      assign_async(socket, [:bookings], fn ->
        {:ok, %{bookings: []}}
      end)
    end
  end

  defp load_async_connected_assigns(socket) do
    %{current_roles: current_roles, current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    assign_async(socket, [:bookings], fn ->
      bookings =
        current_roles
        |> Enum.flat_map(fn r ->
          r.id
          |> HousingApp.Management.UserTenantRole.get_by_id!(actor: current_user_tenant, tenant: tenant)
          |> then(& &1.role_queries)
          |> Enum.map(& &1.common_query)
          |> Enum.filter(&(&1.resource == :booking))
          |> Enum.flat_map(fn query ->
            HousingApp.Assignments.Service.filter_resource(HousingApp.Assignments.Booking, :list_for_assignments, query,
              actor: current_user_tenant,
              tenant: tenant
            )
          end)
        end)
        |> Enum.uniq_by(&{&1.profile_id, &1.bed_id})

      {:ok, %{bookings: bookings}}
    end)
  end
end
