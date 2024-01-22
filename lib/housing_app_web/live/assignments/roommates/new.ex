defmodule HousingAppWeb.Live.Assignments.Roommates.New do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :new} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Roommate Group</h2>
      <.input field={@ash_form[:name]} label="Name" minlength="1" />
      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    ash_form =
      HousingApp.Assignments.RoommateGroup
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Assignments,
        forms: [auto?: true],
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    {:ok, assign(socket, ash_form: ash_form, sidebar: :residents, page_title: "New Roommate Group")}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    with {:ok, roommate_group} <- AshPhoenix.Form.submit(socket.assigns.ash_form, params),
         {:ok, _roommate} <- add_self_to_group(roommate_group, current_user_tenant, tenant) do
      {:noreply,
       socket
       |> put_flash(:info, "Successfully created the new group.")
       |> push_navigate(to: ~p"/roommates")}
    else
      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end

  defp add_self_to_group(roommate_group, actor, tenant) do
    HousingApp.Assignments.Roommate
    |> Ash.Changeset.for_create(
      :new,
      %{
        roommate_group_id: roommate_group.id
      },
      actor: actor,
      tenant: tenant
    )
    |> HousingApp.Assignments.create()
  end
end
