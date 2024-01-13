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
        <:col :let={ut} label="edit">
          <.button phx-click="edit" phx-value-id={ut.id} phx-target={@myself} type="button">
            Edit
          </.button>
        </:col>
      </.table>

      <.simple_form
        autowidth={false}
        class="mt-4"
        for={@user_form}
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
      >
        <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">
          <span :if={@form_action == :update}>Update User</span>
          <span :if={@form_action == :create}>New User</span>
        </h2>
        <div class="max-w-md">
          <.input :if={@form_action == :create} field={@user_form[:name]} label="Name" />
          <.input :if={@form_action == :create} type="email" field={@user_form[:email]} label="Email" />
          <.input type="select" options={@user_types} field={@user_form[:user_type]} label="User Type" />
        </div>

        <h3 :if={Enum.any?(@roles) && @form_action == :update} class="mb-4 text-lg font-bold text-gray-900 dark:text-white">
          Roles
        </h3>
        <.inputs_for
          :let={role_form}
          :if={Enum.any?(@roles) && @form_action == :update}
          field={@user_form[:user_tenant_roles]}
        >
          <input type="hidden" name={role_form[:tenant_id].name} value={role_form[:tenant_id].value} />
          <input type="hidden" name={role_form[:user_tenant_id].name} value={role_form[:user_tenant_id].value} />
          <div class="space-y-4 md:flex md:space-y-0 md:space-x-4">
            <div class="w-full">
              <.input type="select" options={@roles} field={role_form[:role_id]} label="Role" />
            </div>
            <div class="w-full">
              <.input type="select" options={@time_periods} field={role_form[:time_period_id]} label="Time Period" />
            </div>
            <div :if={is_nil(role_form[:time_period_id].value)} class="w-full">
              <.input type="date" field={role_form[:start_at]} label="Start At" />
            </div>
            <div :if={is_nil(role_form[:time_period_id].value)} class="w-full">
              <.input type="date" field={role_form[:end_at]} label="End At" />
            </div>
            <div class="pt-7">
              <.button
                type="button"
                class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-xs dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
                phx-click="remove-role"
                phx-target={@myself}
                phx-value-path={role_form.name}
              >
                Remove
              </.button>
            </div>
          </div>
        </.inputs_for>

        <:actions>
          <%= if not is_nil(@user_form[:user_tenant_roles].value) && Enum.any?(@roles) do %>
            <.button
              type="button"
              phx-click="add-role"
              phx-target={@myself}
              phx-value-path={@user_form[:user_tenant_roles].name}
            >
              <span :if={@user_form[:user_tenant_roles].value |> Enum.any?()}>Add Additional Role</span>
              <span :if={@user_form[:user_tenant_roles].value |> Enum.empty?()}>Add Role</span>
            </.button>
          <% end %>
          <.button>
            <span :if={@form_action == :update}>Update User</span>
            <span :if={@form_action == :create}>Add User</span>
          </.button>
          <.button type="reset" name="reset">Reset Form</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def update(params, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = params

    time_period_options = current_user_tenant |> time_periods(tenant) |> Enum.map(&{&1.name, &1.id})

    {:ok,
     socket
     |> assign(params)
     |> assign(
       form_action: :create,
       user_types: user_type_options(),
       time_periods: [{"Custom", nil}] ++ time_period_options,
       user_tenants: user_tenants(current_user_tenant),
       roles: roles(current_user_tenant, tenant),
       user_form: new_user_form()
     )}
  end

  def handle_event("validate", %{"_target" => ["reset"]}, socket) do
    {:noreply, assign(socket, user_form: new_user_form(), form_action: :create)}
  end

  def handle_event("validate", %{"u_form" => params}, socket) do
    user_form = AshPhoenix.Form.validate(socket.assigns.user_form, params)
    {:noreply, assign(socket, user_form: user_form)}
  end

  def handle_event("add-role", %{"path" => path}, socket) do
    user_form =
      AshPhoenix.Form.add_form(socket.assigns.user_form, path,
        params: %{
          user_tenant_id: socket.assigns.current_user_tenant.id,
          tenant_id: socket.assigns.current_user_tenant.tenant_id
        }
      )

    {:noreply, assign(socket, user_form: user_form)}
  end

  def handle_event("remove-role", %{"path" => path}, socket) do
    user_form = AshPhoenix.Form.remove_form(socket.assigns.user_form, path)
    {:noreply, assign(socket, user_form: user_form)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    %{user_tenants: user_tenants, current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case Enum.find(user_tenants, &(&1.id == id)) do
      nil ->
        {:noreply, socket}

      user_tenant ->
        user_form =
          user_tenant
          |> AshPhoenix.Form.for_update(:update,
            api: HousingApp.Accounts,
            forms: [
              user_tenant_roles: [
                type: :list,
                data: user_tenant.user_tenant_roles,
                resource: HousingApp.Management.UserTenantRole,
                api: HousingApp.Management,
                update_action: :update,
                create_action: :new
              ]
            ],
            as: "u_form",
            actor: current_user_tenant,
            tenant: tenant
          )
          |> Phoenix.Component.to_form()

        {:noreply, assign(socket, user_form: user_form, form_action: :update)}
    end
  end

  # Update
  def handle_event("submit", %{"u_form" => params}, %{assigns: %{user_form: %{source: %{action: :update}}}} = socket) do
    %{user_form: user_form, current_user_tenant: current_user_tenant} = socket.assigns

    # TODO: If they change from custom back to a time period, we need to reset the start_at and end_at fields
    #       Pattern match on the validate event to know when they change, and alter accordingly

    case AshPhoenix.Form.submit(user_form, params: params) do
      {:ok, _app} ->
        {:noreply,
         assign(socket,
           form_action: :create,
           user_form: new_user_form(),
           user_tenants: user_tenants(current_user_tenant)
         )}

      {:error, user_form} ->
        IO.inspect(user_form.source)
        {:noreply, assign(socket, user_form: user_form)}
    end
  end

  # Create
  def handle_event("submit", %{"u_form" => data}, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Accounts.Service.invite_user_to_tenant(data["email"], data["name"], data["user_type"],
           actor: current_user_tenant
         ) do
      {:ok, _ut} ->
        {:noreply,
         assign(socket,
           form_action: :create,
           user_form: new_user_form(),
           user_tenants: user_tenants(current_user_tenant)
         )}

      {:error, err} ->
        IO.inspect(err)
        # TODO: Display flash
        {:noreply, socket}
    end
  end

  defp user_tenants(current_user_tenant) do
    HousingApp.Accounts.UserTenant.list_staff!(actor: current_user_tenant)
  end

  defp roles(current_user_tenant, tenant) do
    [actor: current_user_tenant, tenant: tenant]
    |> HousingApp.Management.Role.list!()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp new_user_form do
    Phoenix.Component.to_form(%{"user_type" => :staff}, as: "u_form")
  end
end
