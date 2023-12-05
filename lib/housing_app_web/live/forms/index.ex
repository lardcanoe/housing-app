defmodule HousingAppWeb.Live.Forms.Index do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.table id="forms" rows={@forms} pagination={false} row_id={fn row -> "forms-row-#{row.id}" end}>
      <:button>
        <svg class="h-3.5 w-3.5 mr-2" fill="currentColor" viewbox="0 0 20 20" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
          <path clip-rule="evenodd" fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" />
        </svg>
        <.link patch={~p"/forms/new"}>
          Add form
        </.link>
      </:button>
      <:col :let={form} :if={@current_user.role == :platform_admin} label="id">
        <%= form.id %>
      </:col>
      <:col :let={form} label="name">
        <a href={~p"/forms/#{form.id}"}><%= form.name %></a>
      </:col>
      <:col :let={form} label="status">
        <span
          :if={form.status == :draft}
          class="bg-yellow-100 text-yellow-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded dark:bg-yellow-900 dark:text-yellow-300"
        >
          Draft
        </span>
        <span
          :if={form.status == :approved}
          class="bg-green-100 text-green-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded dark:bg-green-900 dark:text-green-300"
        >
          Approved
        </span>
        <span
          :if={form.status == :archived}
          class="bg-gray-100 text-gray-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded dark:bg-gray-700 dark:text-gray-300"
        >
          Archived
        </span>
      </:col>
      <:action :let={form}>
        <.link patch={~p"/forms/#{form.id}/edit"} class="block py-2 px-4 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white">
          Edit
        </.link>
      </:action>
    </.table>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: current_tenant}} = socket) do
    case HousingApp.Management.Form.list(actor: current_user_tenant, tenant: current_tenant) do
      {:ok, forms} ->
        {:ok, assign(socket, forms: forms, page_title: "Forms")}

      _ ->
        {:ok, socket |> assign(forms: [], page_title: "Forms") |> put_flash(:error, "Error loading forms.")}
    end
  end
end
