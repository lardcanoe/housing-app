defmodule HousingAppWeb.Live.Reporting.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <section class="bg-gray-50 dark:bg-gray-900">
      <div class="py-8 px-4 mx-auto max-w-screen-xl sm:py-16 lg:px-6">
        <div class="mx-auto max-w-screen-md text-center mb-8 lg:mb-16">
          <h2 class="mb-4 text-4xl tracking-tight font-extrabold text-gray-900 dark:text-white">
            Housing Reports
          </h2>
          <p class="font-light text-gray-500 dark:text-gray-400 sm:text-xl">
            Submission stats for approved housing applications.
          </p>
        </div>

        <div class="space-y-8 md:grid md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 md:gap-8 xl:gap-8 md:space-y-0">
          <%= render_housing_applications(assigns) %>
          <%= render_bookings(assigns) %>
        </div>
      </div>
    </section>
    """
  end

  defp render_housing_applications(assigns) do
    ~H"""
    <div :if={@applications.loading} role="status" class="max-w-sm animate-pulse">
      <%= render_skeleton(%{title: "Applications"}) %>
    </div>

    <%= if @applications.ok? && @applications.result do %>
      <div :for={application <- @applications.result} class="p-6 bg-white rounded shadow dark:bg-gray-800">
        <p class="mb-4 text-2xl text-center font-bold text-gray-100 dark:text-gray-400">
          <%= application.count_of_submissions %> submissions
        </p>
        <h3 class="text-base font-bold dark:text-white"><%= application.name %></h3>
      </div>
    <% end %>
    """
  end

  defp render_bookings(assigns) do
    ~H"""
    <div :if={@bookings.loading} role="status" class="max-w-sm animate-pulse">
      <%= render_skeleton(%{title: "Bookings"}) %>
    </div>

    <%= if @bookings.ok? && @bookings.result do %>
      <div :for={booking <- @bookings.result} class="p-6 bg-white rounded shadow dark:bg-gray-800">
        <p class="mb-4 text-2xl text-center font-bold text-gray-100 dark:text-gray-400">
          <%= booking.count %> bookings
        </p>
        <h3 class="text-base font-bold dark:text-white"><%= booking.time_period.name %></h3>
        <h3 class="text-base font-bold dark:text-white"><%= booking.application.name %></h3>
      </div>
    <% end %>
    """
  end

  defp render_skeleton(assigns) do
    ~H"""
    <h3 class="mb-2 text-xl font-bold dark:text-white"><%= @title %></h3>
    <div class="h-2.5 bg-gray-200 rounded-full dark:bg-gray-700 w-48 mb-4"></div>
    <div class="h-2 bg-gray-200 rounded-full dark:bg-gray-700 max-w-[360px] mb-2.5"></div>
    <div class="h-2 bg-gray-200 rounded-full dark:bg-gray-700 mb-2.5"></div>
    <div class="h-2 bg-gray-200 rounded-full dark:bg-gray-700 max-w-[330px] mb-2.5"></div>
    <div class="h-2 bg-gray-200 rounded-full dark:bg-gray-700 max-w-[300px] mb-2.5"></div>
    <div class="h-2 bg-gray-200 rounded-full dark:bg-gray-700 max-w-[360px]"></div>
    <span class="sr-only">Loading...</span>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(sidebar: :reporting, page_title: "Reporting Dashboard")
     |> load_housing()
     |> load_bookings()}
  end

  defp load_housing(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    assign_async(socket, [:applications], fn ->
      applications =
        HousingApp.Management.Reporting.housing_application_submissions(actor: current_user_tenant, tenant: tenant)

      {:ok, %{applications: applications}}
    end)
  end

  defp load_bookings(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    assign_async(socket, [:bookings], fn ->
      bookings =
        HousingApp.Assignments.Booking.stats_by_time_period!(actor: current_user_tenant, tenant: tenant)

      {:ok, %{bookings: bookings}}
    end)
  end
end
