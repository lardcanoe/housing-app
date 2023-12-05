defmodule HousingAppWeb.Live.HomeLive do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index, current_user_tenant: %{user_type: :user}} = assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-32 md:h-64">
        Student stuff
      </div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-32 md:h-64"></div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-32 md:h-64"></div>
    </div>
    """
  end

  def render(%{live_action: :index, current_user_tenant: %{user_type: :staff}} = assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-32 md:h-64">
        Staff Stuff
      </div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-32 md:h-64"></div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-32 md:h-64"></div>
    </div>
    """
  end

  def render(%{live_action: :index, current_user_tenant: %{user_type: :admin}} = assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-32 md:h-64">
        <.simple_form for={@create_form} phx-change="validate" phx-submit="submit">
          <.input field={@create_form[:name]} label="Name" />
          <:flex_inputs></:flex_inputs>
          <:actions>
            <.button>Save</.button>
            <.button type="delete">Delete</.button>
          </:actions>
        </.simple_form>
      </div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-32 md:h-64"></div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-32 md:h-64"></div>
    </div>
    <div id="myGrid" style="width: 100%; height: 400px;" class="ag-theme-quartz" phx-hook="AgGrid"></div>
    """
  end

  def mount(_params, _session, socket) do
    form =
      HousingApp.Accounts.Tenant
      |> AshPhoenix.Form.for_create(:create,
        api: HousingApp.Accounts,
        forms: [
          items: [
            type: :list,
            resource: HousingApp.Accounts.Tenant,
            create_action: :create
          ]
        ]
      )
      |> to_form()

    {:ok, assign(socket, create_form: form, page_title: "Dashboard")}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    create_form = AshPhoenix.Form.validate(socket.assigns.create_form, params)
    {:noreply, assign(socket, create_form: create_form)}
  end

  def handle_event("load-data", %{}, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.create_form, params: params) do
      {:ok, tenant} ->
        {:ok, _ut} =
          HousingApp.Accounts.create_user_tenant(
            %{
              tenant_id: tenant.id,
              user_id: socket.assigns.current_user.id,
              user_type: :admin
            },
            actor: socket.assigns.current_user
          )

        {:noreply,
         socket
         |> put_flash(:info, "Saved tenant for #{tenant.name}!")
         |> push_navigate(to: ~p"/switch-tenant/#{tenant.id}")}

      {:error, create_form} ->
        {:noreply, assign(socket, create_form: create_form)}
    end
  end
end
