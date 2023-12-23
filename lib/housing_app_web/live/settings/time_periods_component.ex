defmodule HousingAppWeb.Components.TimePeriodsForm do
  @moduledoc false

  use HousingAppWeb, :live_component

  import HousingAppWeb.CoreComponents

  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true

  def render(%{tp_form: nil} = assigns) do
    ~H"""
    <div class="hidden"></div>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <.table
        :if={@time_periods != []}
        id="time_periods"
        rows={@time_periods}
        pagination={false}
        row_id={fn row -> "time-period-row-#{row.id}" end}
      >
        <:col :let={tp} label="name">
          <%= tp.name %>
        </:col>
        <:col :let={tp} label="start_at">
          <%= tp.start_at %>
        </:col>
        <:col :let={tp} label="end_at">
          <%= tp.end_at %>
        </:col>
        <:col :let={tp} label="status">
          <%= tp.status %>
        </:col>
      </.table>

      <.simple_form
        autowidth={false}
        class="max-w-lg mt-4"
        for={@tp_form}
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
      >
        <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Time Period</h2>
        <.input field={@tp_form[:name]} label="Name" />
        <.input type="date" field={@tp_form[:start_at]} label="Start At" />
        <.input type="date" field={@tp_form[:end_at]} label="End At" />

        <:actions>
          <.button>Create</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, tp_form: nil, time_periods: [])}
  end

  def update(%{current_user_tenant: current_user_tenant, current_tenant: tenant}, socket) do
    {:ok,
     assign(socket,
       time_periods: time_periods(current_user_tenant, tenant),
       tp_form: new_management_ash_form(HousingApp.Management.TimePeriod, current_user_tenant, tenant),
       current_user_tenant: current_user_tenant,
       current_tenant: tenant
     )}
  end

  def handle_event("validate", _data, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"form" => data}, socket) do
    %{assigns: %{tp_form: tp_form, current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket

    case AshPhoenix.Form.submit(tp_form, params: data) do
      {:ok, _tp} ->
        {:noreply,
         assign(socket,
           tp_form: new_management_ash_form(HousingApp.Management.TimePeriod, current_user_tenant, tenant),
           time_periods: time_periods(current_user_tenant, tenant)
         )}

      {:error, tp_form} ->
        {:noreply, assign(socket, tp_form: tp_form)}
    end
  end
end
