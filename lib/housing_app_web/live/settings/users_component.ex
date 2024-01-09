defmodule HousingAppWeb.Components.Settings.User do
  @moduledoc false

  use HousingAppWeb, :live_component

  import HousingApp.Cldr, only: [format_time: 2]
  import HousingAppWeb.CoreComponents

  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true
  attr :locale, :string, required: true
  attr :timezone, :string, required: true

  def render(%{user_form: nil} = assigns) do
    ~H"""
    <div class="hidden"></div>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <.table
        :if={@user_tenants != []}
        id="user-tenants-table"
        rows={@user_tenants}
        pagination={false}
        row_id={fn row -> "user-row-#{row.id}" end}
      >
        <:col :let={ut} label="avatar">
          <.gravatar
            email={ut.user.email |> Ash.CiString.to_comparable_string()}
            alternate={ut.user.avatar}
            alt={ut.user.name}
          />
        </:col>
        <:col :let={ut} label="name">
          <%= ut.user.name %>
        </:col>
        <:col :let={ut} label="email">
          <%= ut.user.email %>
        </:col>
        <:col :let={ut} label="type">
          <%= ut.user_type %>
        </:col>
        <:col :let={ut} label="has api key?">
          <.icon :if={!is_nil(ut.api_key) && ut.api_key != ""} name="hero-check-solid" />
        </:col>
        <:col :let={ut} label="created at">
          <%= format_time(ut.created_at, locale: @locale, timezone: @timezone) %>
        </:col>
      </.table>

      <.simple_form
        autowidth={false}
        class="max-w-lg mt-4"
        for={@user_form}
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
      >
        <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New User</h2>
        <.input field={@user_form[:name]} label="Name" />
        <.input type="email" field={@user_form[:email]} label="Email" />
        <.input type="select" options={@user_types} field={@user_form[:user_type]} label="User Type" />

        <:actions>
          <.button>Add</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, user_form: nil, user_tenants: [], user_types: user_type_options())}
  end

  def update(params, socket) do
    %{current_user_tenant: current_user_tenant} = params

    {:ok,
     socket
     |> assign(params)
     |> assign(
       user_tenants: user_tenants(current_user_tenant),
       user_form: to_form(%{"user_type" => :staff}, as: "u_form")
     )}
  end

  def handle_event("validate", _data, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"u_form" => data}, socket) do
    %{current_user_tenant: current_user_tenant} = socket.assigns

    case HousingApp.Accounts.Service.invite_user_to_tenant(data["email"], data["name"], data["user_type"],
           actor: current_user_tenant
         ) do
      {:ok, _ut} ->
        {:noreply,
         assign(socket,
           user_form: to_form(%{}, as: "u_form"),
           user_tenants: user_tenants(current_user_tenant)
         )}

      {:error, user_form} ->
        {:noreply, assign(socket, user_form: user_form)}
    end
  end

  defp user_tenants(current_user_tenant) do
    HousingApp.Accounts.UserTenant.list_staff!(actor: current_user_tenant)
  end
end
