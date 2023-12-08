defmodule HousingAppWeb.Live.Profiles.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Profiles</h1>

    <.table id="profiles" rows={@profiles} pagination={false} row_id={fn row -> "profiles-row-#{row.id}" end}>
      <:button>
        <svg
          class="h-3.5 w-3.5 mr-2"
          fill="currentColor"
          viewbox="0 0 20 20"
          xmlns="http://www.w3.org/2000/svg"
          aria-hidden="true"
        >
          <path
            clip-rule="evenodd"
            fill-rule="evenodd"
            d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
          />
        </svg>
        <.link patch={~p"/profiles/new"}>
          Add profile
        </.link>
      </:button>
      <:col :let={profile} :if={@current_user.role == :platform_admin} label="id">
        <%= profile.id %>
      </:col>
      <:col :let={profile} label="User Name">
        <.link patch={~p"/profiles/#{profile.id}/edit"}><%= profile.user_tenant.user.name %></.link>
      </:col>
      <:col :let={profile} label="User Email">
        <%= profile.user_tenant.user.email %>
      </:col>
      <:action :let={profile}>
        <.link
          patch={~p"/profiles/#{profile.id}/edit"}
          class="block py-2 px-4 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
        >
          Edit
        </.link>
      </:action>
    </.table>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    {:ok, profiles} = HousingApp.Management.Profile.list(actor: current_user_tenant, tenant: tenant)

    {:ok, assign(socket, profiles: profiles, page_title: "Profiles")}
  end
end
