defmodule HousingAppWeb.Live.Profiles.New do
  @moduledoc false
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :new} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Profile</h2>
      <.async_result :let={user_tenants} assign={@user_tenants}>
        <:loading>
          <.input
            type="select"
            field={@ash_form[:user_tenant_id]}
            options={[]}
            label="Student"
            prompt="Loading students..."
            disabled
          />
        </:loading>
        <:failed :let={reason}><%= reason %></:failed>
        <.input
          type="select"
          field={@ash_form[:user_tenant_id]}
          options={user_tenants}
          label="Student"
          prompt="Select a student..."
          required
        />
      </.async_result>

      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    ash_form =
      HousingApp.Management.Profile
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Management,
        forms: [auto?: true],
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    {:ok, socket |> assign(ash_form: ash_form, sidebar: :residents, page_title: "New Profile") |> load_async_assigns()}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully created the profile.")
         |> push_navigate(to: ~p"/profiles")}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end

  def load_async_assigns(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    assign_async(socket, [:user_tenants], fn ->
      user_tenants =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Accounts.UserTenant.list_students!()
        |> Enum.sort_by(& &1.user.name)
        |> Enum.map(fn ut ->
          {"#{ut.user.name} (#{ut.user.email})", ut.id}
        end)

      {:ok, %{user_tenants: user_tenants}}
    end)
  end
end
