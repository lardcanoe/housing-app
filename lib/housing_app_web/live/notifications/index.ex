defmodule HousingAppWeb.Live.Notifications.Index do
  @moduledoc false
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingApp.Cldr, only: [format_time: 2]

  on_mount HousingAppWeb.LiveLocale

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div :if={@notifications.loading} role="status" class="max-w-sm animate-pulse text-gray-400 dark:text-gray-500">
      Loading...
    </div>

    <%= if @notifications.ok? && @notifications.result do %>
      <ol class="relative border-s border-gray-200 dark:border-gray-700">
        <li :for={notification <- @notifications.result} class="mb-10 ms-4">
          <div class={[
            "absolute w-3 h-3 rounded-full mt-1.5 -start-1.5 border border-white dark:border-gray-900 dark:bg-gray-700",
            notification.read && "bg-gray-200",
            not notification.read && "bg-green-500"
          ]}>
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
    if connected?(socket) do
      socket
      |> assign(unread_notifications: 0)
      |> assign_async([:notifications], fn ->
        {:ok, %{notifications: fetch_notifications(socket)}}
      end)
    else
      assign_async(socket, [:notifications], fn ->
        {:ok, %{notifications: []}}
      end)
    end
  end

  defp fetch_notifications(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    # FUTURE: Use a bulk_update

    [actor: current_user_tenant, tenant: tenant]
    |> HousingApp.Management.Notification.list!()
    |> Enum.map(fn n ->
      if not n.read do
        HousingApp.Management.Notification.mark_as_read!(n, actor: current_user_tenant, tenant: tenant)
      end

      # Return original `n` so we can show it as "unread" in the UI, even though we just marked it as read
      n
    end)
  end
end
