defmodule HousingAppWeb.Components.Settings.Roles do
  @moduledoc false

  use HousingAppWeb, :live_component

  import HousingApp.Cldr, only: [format_time: 2]
  import HousingAppWeb.CoreComponents

  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true
  attr :locale, :string, required: true
  attr :timezone, :string, required: true

  def render(%{role_form: nil} = assigns) do
    ~H"""
    <div class="hidden"></div>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <.table
        :if={@roles != []}
        id="roles-table"
        rows={@roles}
        pagination={false}
        row_id={fn row -> "role-row-#{row.id}" end}
      >
        <:col :let={r} label="name">
          <%= r.name %>
        </:col>
        <:col :let={r} label="description">
          <%= r.description %>
        </:col>
        <:col :let={r} label="created at">
          <%= format_time(r.created_at, locale: @locale, timezone: @timezone) %>
        </:col>
        <:col :let={r} label="edit">
          <.button phx-click="edit" phx-value-id={r.id} phx-target={@myself} type="button">
            Edit
          </.button>
        </:col>
      </.table>

      <.simple_form
        autowidth={false}
        class="max-w-lg mt-4"
        for={@role_form}
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
      >
        <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">
          <span :if={@role_form.source.action == :update}>Edit Role</span>
          <span :if={@role_form.source.action == :new}>New Role</span>
        </h2>

        <.input field={@role_form[:name]} label="Name" />
        <.input field={@role_form[:description]} label="Description" />

        <h3 class="mb-4 text-lg font-bold text-gray-900 dark:text-white">Permissions</h3>
        <.inputs_for :let={perm_form} field={@role_form[:permissions]}>
          <div class="space-y-4 md:flex md:space-y-0 md:space-x-4">
            <div class="w-full">
              <.input type="select" options={@role_resource_options} field={perm_form[:resource]} label="Resource" />
            </div>
            <div class="w-full">
              <label class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">
                Access
              </label>
              <div class="flex items-center space-x-4">
                <div class="flex items-center">
                  <.input type="checkbox" field={perm_form[:read]} label="Read" />
                </div>
                <div class="flex items-center">
                  <.input type="checkbox" field={perm_form[:write]} label="Write" />
                </div>
              </div>
            </div>
            <div class="pt-7">
              <.button
                type="button"
                class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-xs dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
                phx-click="remove-permission"
                phx-target={@myself}
                phx-value-path={perm_form.name}
              >
                Remove
              </.button>
            </div>
          </div>
        </.inputs_for>

        <:actions>
          <.button
            type="button"
            phx-click="add-permission"
            phx-target={@myself}
            phx-value-path={@role_form[:permissions].name}
          >
            <span :if={Enum.any?(AshPhoenix.Form.value(@role_form, :permissions))}>Add Additional Permission</span>
            <span :if={Enum.empty?(AshPhoenix.Form.value(@role_form, :permissions))}>Add Permission</span>
          </.button>
          <.button>
            <span :if={@role_form.source.action == :update}>Update Role</span>
            <span :if={@role_form.source.action == :new}>Create Role</span>
          </.button>
          <.button type="reset" name="reset">Reset Form</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, role_form: nil, roles: [], role_resource_options: role_resource_options())}
  end

  def update(params, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = params

    role_form =
      HousingApp.Management.Role
      |> management_form_for_create(:new,
        as: "role_form",
        actor: current_user_tenant,
        tenant: tenant
      )
      |> AshPhoenix.Form.add_form("role_form[permissions]", params: %{resource: :profile})

    {:ok,
     socket
     |> assign(params)
     |> assign(
       roles: roles(current_user_tenant, tenant),
       role_form: role_form
     )}
  end

  def handle_event("validate", %{"_target" => ["reset"]}, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    {:noreply,
     assign(socket,
       role_form:
         management_form_for_create(HousingApp.Management.Role, :new,
           as: "role_form",
           actor: current_user_tenant,
           tenant: tenant
         )
     )}
  end

  def handle_event("validate", %{"role_form" => params}, socket) do
    role_form = AshPhoenix.Form.validate(socket.assigns.role_form, params)
    {:noreply, assign(socket, role_form: role_form)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    %{roles: roles, current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case Enum.find(roles, &(&1.id == id)) do
      nil ->
        {:noreply, socket}

      role ->
        {:noreply,
         assign(socket,
           role_form:
             management_form_for_update(role, :update, as: "role_form", actor: current_user_tenant, tenant: tenant)
         )}
    end
  end

  def handle_event("add-permission", %{"path" => path}, socket) do
    role_form = AshPhoenix.Form.add_form(socket.assigns.role_form, path, params: %{resource: :profile})
    {:noreply, assign(socket, role_form: role_form)}
  end

  def handle_event("remove-permission", %{"path" => path}, socket) do
    role_form = AshPhoenix.Form.remove_form(socket.assigns.role_form, path)
    {:noreply, assign(socket, role_form: role_form)}
  end

  def handle_event("submit", %{"role_form" => params}, socket) do
    %{role_form: role_form, current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case AshPhoenix.Form.submit(role_form, params: params) do
      {:ok, _app} ->
        {:noreply,
         assign(socket,
           role_form:
             management_form_for_create(HousingApp.Management.Role, :new,
               as: "role_form",
               actor: current_user_tenant,
               tenant: tenant
             ),
           roles: roles(current_user_tenant, tenant)
         )}

      {:error, role_form} ->
        IO.inspect(role_form.source)
        {:noreply, assign(socket, role_form: role_form)}
    end
  end

  defp roles(current_user_tenant, tenant) do
    HousingApp.Management.Role.list!(actor: current_user_tenant, tenant: tenant)
  end
end
