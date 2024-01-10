defmodule HousingAppWeb.Live.Assignments.Roommates.User do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-4">
      <%= render_groups(%{groups: @roommates}) %>
      <%= render_invites(%{groups: @invites}) %>
      <div
        :if={length(@roommates) < 5}
        class="max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700"
      >
        <h5 class="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
          New Group
        </h5>
        <p class="mb-3 font-normal text-gray-700 dark:text-gray-400">
          Create a new group of roommates to use in your housing application.
        </p>
        <.link
          navigate={~p"/roommates/new"}
          class="inline-flex items-center px-3 py-2 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
        >
          <span>
            Create
          </span>
          <svg
            class="rtl:rotate-180 w-3.5 h-3.5 ms-2"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 14 10"
          >
            <path
              stroke="currentColor"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M1 5h12m0 0L9 1m4 4L9 9"
            />
          </svg>
        </.link>
      </div>
    </div>
    """
  end

  defp render_groups(assigns) do
    ~H"""
    <div
      :for={roommate <- @groups}
      class="max-w-md p-4 bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700"
    >
      <%= render_group(%{group: roommate}) %>

      <.link
        phx-click={show_modal("invite-modal-#{roommate.roommate_group_id}")}
        class="inline-flex items-center px-3 py-2 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
      >
        <.icon name="hero-plus-solid" class="flex-shrink-0 w-4 h-4" /> Invite Another
      </.link>

      <.custom_modal id={"invite-modal-#{roommate.roommate_group_id}"}>
        <:title>Invite a new roommate to <%= roommate.roommate_group.name %></:title>
        <div class="mt-2 mb-4 dark:text-white">
          <.simple_form :let={f} for={to_form(%{"emails" => "", "id" => roommate.roommate_group_id})} phx-submit="invite">
            <.input type="hidden" field={f[:id]} />
            <.input
              id={"email-#{roommate.roommate_group_id}"}
              field={f[:emails]}
              type="email"
              multiple
              label="Email(s), comma separated"
            />
            <:actions>
              <.button
                phx-click={hide_modal("invite-modal-#{roommate.roommate_group_id}")}
                type="submit"
                phx-disable-with={gettext("Inviting...")}
              >
                <%= gettext("Invite") %>
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </.custom_modal>
    </div>
    """
  end

  defp render_invites(assigns) do
    ~H"""
    <div
      :for={invite <- @groups}
      class="max-w-md p-4 bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700"
    >
      <%= render_group(%{group: invite}) %>

      <div class="flex items-center space-x-4">
        <button
          phx-click="accept"
          phx-value-id={invite.id}
          class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
        >
          Accept
        </button>
        <button
          phx-click="decline"
          phx-value-id={invite.id}
          class="text-red-600 inline-flex items-center hover:text-white border border-red-600 hover:bg-red-600 focus:ring-4 focus:outline-none focus:ring-red-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:border-red-500 dark:text-red-500 dark:hover:text-white dark:hover:bg-red-600 dark:focus:ring-red-900"
        >
          Decline
        </button>
      </div>
    </div>
    """
  end

  defp render_group(assigns) do
    ~H"""
    <h1 class="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
      <%= @group.roommate_group.name %>
    </h1>
    <p :for={member <- @group.roommate_group.members} class="mb-3 font-normal text-gray-700 dark:text-gray-400">
      <%= member.user_tenant.user.name %> <%= member.user_tenant.user.email %>
    </p>
    <h2
      :if={Enum.reject(@group.roommate_group.invites, &(&1.status == :accepted)) != []}
      class="mb-2 text-lg font-bold tracking-tight text-gray-900 dark:text-white"
    >
      Invites
    </h2>
    <p
      :for={invite <- Enum.reject(@group.roommate_group.invites, &(&1.status == :accepted))}
      class="mb-3 font-normal text-gray-700 dark:text-gray-400"
    >
      <%= invite.user_tenant.user.name %> <%= invite.user_tenant.user.email %> (<%= invite.status %>)
    </p>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, load_roommate_groups(socket)}
  end

  defp load_roommate_groups(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    {:ok, roommates} =
      HousingApp.Assignments.Roommate.list_mine(
        actor: current_user_tenant,
        tenant: tenant,
        load: [roommate_group: [members: [user_tenant: [:user]], invites: [user_tenant: [:user]]]]
      )

    {:ok, invites} =
      HousingApp.Assignments.RoommateInvite.list_mine(
        actor: current_user_tenant,
        tenant: tenant,
        load: [roommate_group: [members: [user_tenant: [:user]], invites: [user_tenant: [:user]]]]
      )

    assign(socket, roommates: roommates, invites: invites)
  end

  def handle_event("invite", %{"emails" => emails, "id" => roommate_group_id}, socket) do
    with {:load_group, {:ok, group}} <- {:load_group, load_group(socket, roommate_group_id)},
         {:find_user_tenants, user_tenants} when user_tenants != [] <-
           {:find_user_tenants, find_user_tenants(socket, emails)},
         {:invite_user_tenants, _invites} <-
           {:invite_user_tenants, invite_user_tenants(socket, group, user_tenants)} do
      {:noreply, load_roommate_groups(socket)}
    else
      {:load_group, _} ->
        {:noreply, socket}

      {:find_user_tenants, _} ->
        {:noreply, socket}

      {:invite_user_tenants, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("accept", %{"id" => invite_id}, socket) do
    %{current_user_tenant: actor, current_tenant: tenant} = socket.assigns

    case HousingApp.Assignments.RoommateInvite.get_by_id(invite_id, actor: actor, tenant: tenant) do
      {:ok, invite} ->
        HousingApp.Assignments.RoommateInvite.accept(invite, actor: actor, tenant: tenant)

        HousingApp.Assignments.Roommate.new(
          %{
            roommate_group_id: invite.roommate_group_id,
            roommate_invite_id: invite.id
          },
          actor: actor,
          tenant: tenant
        )

        {:noreply, load_roommate_groups(socket)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("decline", %{"id" => invite_id}, socket) do
    %{current_user_tenant: actor, current_tenant: tenant} = socket.assigns

    case HousingApp.Assignments.RoommateInvite.get_by_id(invite_id, actor: actor, tenant: tenant) do
      {:ok, invite} ->
        HousingApp.Assignments.RoommateInvite.decline(invite, actor: actor, tenant: tenant)

        {:noreply, load_roommate_groups(socket)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  defp load_group(socket, roommate_group_id) do
    %{current_user_tenant: actor, current_tenant: tenant} = socket.assigns
    HousingApp.Assignments.RoommateGroup.get_by_id(roommate_group_id, actor: actor, tenant: tenant)
  end

  defp find_user_tenants(socket, emails) do
    emails
    |> Enum.map(&String.trim/1)
    |> Enum.map(&find_user_tenant(socket, &1))
    |> Enum.reject(&is_nil/1)
  end

  defp find_user_tenant(socket, email) do
    %{current_user_tenant: actor, current_tenant: tenant} = socket.assigns

    case HousingApp.Accounts.UserTenant.get_user_by_email(email, actor: actor, tenant: tenant) do
      {:ok, user_tenant} -> user_tenant
      {:error, _} -> nil
    end
  end

  defp invite_user_tenants(socket, group, user_tenants) do
    Enum.map(user_tenants, &invite_user_tenant(socket, group, &1))
  end

  defp invite_user_tenant(socket, group, user_tenant) do
    %{current_user_tenant: actor, current_tenant: tenant} = socket.assigns

    # TODO: Check if exists, and if accepted, do nothing. If declined, do nothing.
    # TODO: Don't allow inviting self
    {:ok, _invite} =
      HousingApp.Assignments.RoommateInvite.invite(%{roommate_group_id: group.id, user_tenant_id: user_tenant.id},
        actor: actor,
        tenant: tenant,
        upsert?: true
      )
  end
end
