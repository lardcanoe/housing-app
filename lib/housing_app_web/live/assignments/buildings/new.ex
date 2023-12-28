defmodule HousingAppWeb.Live.Assignments.Buildings.New do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :new} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Building</h2>
      <.input field={@ash_form[:name]} label="Name" />
      <.input field={@ash_form[:location]} label="Location" />
      <.input type="number" field={@ash_form[:floor_count]} label="Floors" />
      <.input type="number" field={@ash_form[:room_count]} label="Rooms" />
      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    ash_form =
      HousingApp.Assignments.Building
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Assignments,
        forms: [auto?: true],
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    {:ok, assign(socket, ash_form: ash_form, sidebar: :assignments, page_title: "New Building")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    with %{source: %{valid?: true}} = ash_form <- AshPhoenix.Form.validate(socket.assigns.ash_form, params),
         {:ok, _app} <- AshPhoenix.Form.submit(ash_form) do
      {:noreply,
       socket
       |> put_flash(:info, "Successfully created the building.")
       |> push_navigate(to: ~p"/assignments/buildings")}
    else
      %{source: %{valid?: false}} = ash_form ->
        {:noreply, assign(socket, ash_form: ash_form)}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
