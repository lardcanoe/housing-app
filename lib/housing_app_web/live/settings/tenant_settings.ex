defmodule HousingAppWeb.Live.Settings.TenantSettings do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  # https://flowbite.com/blocks/application/crud-update-forms/#update-user-form
  def render(%{live_action: :index} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Account Settings</h1>
    <div class="md:flex">
      <ul
        id="default-tab"
        data-tabs-toggle="#default-tab-content"
        role="tablist"
        class="flex-column md:w-52 space-y space-y-4 text-sm font-medium text-gray-500 dark:text-gray-400 md:me-4 mb-4 md:mb-0"
      >
        <li role="presentation">
          <a
            href="#"
            class="inline-flex items-center px-4 py-3 rounded-lg hover:text-gray-900 bg-gray-50 hover:bg-gray-100 w-full dark:bg-gray-800 dark:hover:bg-gray-700 dark:hover:text-white"
            aria-current="page"
            id="forms-tab"
            data-tabs-target="#forms"
            type="button"
            role="tab"
            aria-controls="forms"
            aria-selected="true"
          >
            <svg
              class="w-4 h-4 me-2 text-white"
              aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path d="M10 0a10 10 0 1 0 10 10A10.011 10.011 0 0 0 10 0Zm0 5a3 3 0 1 1 0 6 3 3 0 0 1 0-6Zm0 13a8.949 8.949 0 0 1-4.951-1.488A3.987 3.987 0 0 1 9 13h2a3.987 3.987 0 0 1 3.951 3.512A8.949 8.949 0 0 1 10 18Z" />
            </svg>
            Forms
          </a>
        </li>
        <li role="presentation">
          <a
            href="#"
            class="inline-flex items-center px-4 py-3 rounded-lg hover:text-gray-900 bg-gray-50 hover:bg-gray-100 w-full dark:bg-gray-800 dark:hover:bg-gray-700 dark:hover:text-white"
            id="time-periods-tab"
            data-tabs-target="#time-periods"
            type="button"
            role="tab"
            aria-controls="time-periods"
            aria-selected="false"
          >
            <svg
              class="w-4 h-4 me-2 text-gray-500 dark:text-gray-400"
              aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg"
              fill="currentColor"
              viewBox="0 0 18 18"
            >
              <path d="M6.143 0H1.857A1.857 1.857 0 0 0 0 1.857v4.286C0 7.169.831 8 1.857 8h4.286A1.857 1.857 0 0 0 8 6.143V1.857A1.857 1.857 0 0 0 6.143 0Zm10 0h-4.286A1.857 1.857 0 0 0 10 1.857v4.286C10 7.169 10.831 8 11.857 8h4.286A1.857 1.857 0 0 0 18 6.143V1.857A1.857 1.857 0 0 0 16.143 0Zm-10 10H1.857A1.857 1.857 0 0 0 0 11.857v4.286C0 17.169.831 18 1.857 18h4.286A1.857 1.857 0 0 0 8 16.143v-4.286A1.857 1.857 0 0 0 6.143 10Zm10 0h-4.286A1.857 1.857 0 0 0 10 11.857v4.286c0 1.026.831 1.857 1.857 1.857h4.286A1.857 1.857 0 0 0 18 16.143v-4.286A1.857 1.857 0 0 0 16.143 10Z" />
            </svg>
            Time Periods
          </a>
        </li>
      </ul>
      <div id="default-tab-content" class="w-full">
        <div
          class="hidden p-4 rounded-lg bg-gray-50 dark:bg-gray-800"
          id="forms"
          role="tabpanel"
          aria-labelledby="forms-tab"
        >
          <%= render_settings_tab(assigns) %>
        </div>
        <div
          class="hidden p-4 rounded-lg bg-gray-50 dark:bg-gray-800"
          id="time-periods"
          role="tabpanel"
          aria-labelledby="time-periods-tab"
        >
          <%= render_time_periods_tab(assigns) %>
        </div>
      </div>
    </div>
    """
  end

  defp render_settings_tab(assigns) do
    ~H"""
    <.simple_form autowidth={false} class="max-w-lg" for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Management</h2>
      <.input type="select" options={@forms} field={@ash_form[:profile_form_id]} label="Default Profile Form" />
      <.input field={@ash_form[:form_types]} label="Form Types" />
      <.input field={@ash_form[:application_types]} label="Application Types" />

      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Assignments</h2>
      <.input type="select" options={@forms} field={@ash_form[:building_form_id]} label="Building Form" />
      <.input type="select" options={@forms} field={@ash_form[:room_form_id]} label="Room Form" />
      <.input type="select" options={@forms} field={@ash_form[:bed_form_id]} label="Bed Form" />
      <.input type="select" options={@forms} field={@ash_form[:booking_form_id]} label="Booking Form" />

      <:actions>
        <.button>Save</.button>
      </:actions>
    </.simple_form>
    """
  end

  defp render_time_periods_tab(assigns) do
    ~H"""
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
      phx-change="validate-time-period"
      phx-submit="submit-time-period"
    >
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Time Period</h2>
      <.input field={@tp_form[:name]} label="Name" />
      <.input type="date" field={@tp_form[:start_at]} label="Start At" />
      <.input type="date" field={@tp_form[:end_at]} label="End At" />

      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    settings =
      HousingApp.Management.TenantSetting.get_settings!(
        actor: current_user_tenant,
        tenant: tenant
      )

    ash_form =
      %{
        "profile_form_id" => settings[{:system, :profile_form_id}] || nil,
        "form_types" => settings[{:system, :form_types}] || "",
        "application_types" => settings[{:system, :application_types}] || "",
        "building_form_id" => settings[{:system, :building_form_id}] || nil,
        "room_form_id" => settings[{:system, :room_form_id}] || nil,
        "bed_form_id" => settings[{:system, :bed_form_id}] || nil,
        "booking_form_id" => settings[{:system, :booking_form_id}] || nil
      }
      |> to_form()

    db_forms =
      HousingApp.Management.Form.list_approved!(actor: current_user_tenant, tenant: tenant)
      |> Enum.map(&{&1.name, &1.id})

    forms =
      [{"-- Select a default --", nil}] ++ db_forms

    time_periods =
      HousingApp.Management.TimePeriod.list!(
        actor: current_user_tenant,
        tenant: tenant
      )

    tp_form =
      HousingApp.Management.TimePeriod
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Management,
        forms: [auto?: true],
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    {:ok,
     assign(socket,
       ash_form: ash_form,
       forms: forms,
       time_periods: time_periods,
       tp_form: tp_form,
       page_title: "Account Settings"
     )}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
  end

  def handle_event("validate", _data, socket) do
    # ash_form = AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, socket}
  end

  def handle_event(
        "submit",
        data,
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    ash_form =
      data
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        case HousingApp.Management.TenantSetting
             |> Ash.Changeset.new()
             |> Ash.Changeset.for_create(:create, %{namespace: :system, setting: String.to_atom(key), value: value},
               actor: current_user_tenant,
               tenant: tenant,
               upsert?: true
             )
             |> HousingApp.Management.create() do
          {:ok, setting} ->
            Map.put(acc, key, setting.value)

          _ ->
            acc
        end
      end)
      |> to_form()

    {:noreply, socket |> assign(ash_form: ash_form) |> put_flash(:info, "Successfully updated account settings.")}
  end

  def handle_event("validate-time-period", _data, socket) do
    {:noreply, socket}
  end

  def handle_event("submit-time-period", %{"form" => data}, socket) do
    %{assigns: %{tp_form: tp_form, current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket

    case AshPhoenix.Form.submit(tp_form, params: data) do
      {:ok, _tp} ->
        time_periods =
          HousingApp.Management.TimePeriod.list!(
            actor: current_user_tenant,
            tenant: tenant
          )

        {:noreply,
         socket
         |> assign(time_periods: time_periods)
         |> put_flash(:info, "Successfully created a time period.")}

      {:error, tp_form} ->
        {:noreply, assign(socket, tp_form: tp_form)}
    end
  end
end
