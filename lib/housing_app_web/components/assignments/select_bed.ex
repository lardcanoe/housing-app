defmodule HousingAppWeb.Components.Assignments.SelectBed do
  @moduledoc false

  use HousingAppWeb, :live_component

  # import HousingAppWeb.CoreComponents, only: [icon: 1]

  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true
  attr :data, :any, required: true

  def render(assigns) do
    ~H"""
    <div>
      <.simple_form for={@form} phx-change="validate" phx-submit="submit" phx-target={@myself}>
        <.async_result :let={beds} assign={@beds}>
          <:loading>
            <.input type="select" field={@form[:bed_id]} options={[]} label="Bed" prompt="Loading beds..." disabled />
          </:loading>
          <:failed :let={reason}><%= reason %></:failed>
          <.input type="select" field={@form[:bed_id]} options={beds} label="Bed" prompt="Select a bed..." required />
        </.async_result>

        <:actions>
          <.button>Next</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(params, socket) do
    %{data: data, current_user_tenant: current_user_tenant, current_tenant: tenant} = params

    {:ok,
     socket
     |> assign(params)
     |> assign(form: to_form(data, as: "form"))
     |> assign_async([:beds], fn ->
       beds =
         [actor: current_user_tenant, tenant: tenant]
         |> HousingApp.Assignments.Bed.list!()
         |> Enum.map(&{"#{&1.room.building.name} / #{&1.room.name} / #{&1.name}", &1.id})
         |> Enum.sort_by(fn {name, _} -> name end)

       {:ok, %{beds: beds}}
     end)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"form" => data}, socket) do
    send(self(), {:component_submit, data})
    {:noreply, socket}
  end
end
