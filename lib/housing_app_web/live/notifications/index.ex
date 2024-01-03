defmodule HousingAppWeb.Live.Notifications.Index do
  @moduledoc false
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingApp.Cldr, only: [format_time: 2]

  on_mount HousingAppWeb.LiveLocale

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div :if={@notifications.loading} role="status" class="max-w-sm animate-pulse">
      Loading...
    </div>

    <%= if @notifications.ok? && @notifications.result do %>
      <ol class="relative border-s border-gray-200 dark:border-gray-700">
        <li :for={notification <- @notifications.result} class="mb-10 ms-4">
          <div class="absolute w-3 h-3 bg-gray-200 rounded-full mt-1.5 -start-1.5 border border-white dark:border-gray-900 dark:bg-gray-700">
          </div>
          <time class="mb-1 text-sm font-normal leading-none text-gray-400 dark:text-gray-500">
            <%= format_time(notification.created_at, locale: @locale, timezone: @timezone) %>
          </time>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white"><%= notification.subject %></h3>
          <p class="text-base font-normal text-gray-500 dark:text-gray-400">
            <%= notification.message %>
          </p>
        </li>
      </ol>
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(sidebar: :overview, page_title: "Notifications") |> load_notifications()}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket |> assign(sidebar: :overview, page_title: "Notifications") |> load_notifications()}
  end

  defp load_notifications(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    if connected?(socket) do
      assign_async(socket, [:notifications], fn ->
        notifications =
          HousingApp.Management.Notification.list!(actor: current_user_tenant, tenant: tenant)

        {:ok, %{notifications: notifications}}
      end)
    else
      assign_async(socket, [:notifications], fn ->
        {:ok, %{notifications: []}}
      end)
    end
  end
end
