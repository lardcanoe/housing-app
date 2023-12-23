defmodule HousingAppWeb.Live.HomeLive do
  @moduledoc false
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
        <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Add Tenant</h1>
        <.simple_form for={@create_form} phx-change="validate" phx-submit="submit">
          <.input field={@create_form[:name]} label="Name" />
          <:flex_inputs></:flex_inputs>
          <:actions>
            <.button>Create</.button>
            <.button :if={false} type="delete">Delete</.button>
          </:actions>
        </.simple_form>
      </div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600">
        <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Generate Fake Data</h1>
        <.simple_form for={@faker_form} phx-change="validate-faker" phx-submit="submit-faker">
          <.input type="number" field={@faker_form[:products]} label="Products" />
          <.input type="number" field={@faker_form[:buildings]} label="Buildings" />
          <.input type="number" field={@faker_form[:rooms]} label="Rooms" />
          <.input type="number" field={@faker_form[:students]} label="Students" />
          <:flex_inputs></:flex_inputs>
          <:actions>
            <.button>Generate</.button>
          </:actions>
        </.simple_form>
      </div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-32 md:h-64"></div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    form =
      HousingApp.Accounts.Tenant
      |> AshPhoenix.Form.for_create(:create,
        api: HousingApp.Accounts,
        forms: [auto?: true]
      )
      |> to_form()

    faker_form =
      to_form(%{"products" => 0, "buildings" => 0, "rooms" => 0, "students" => 0})

    {:ok, assign(socket, create_form: form, faker_form: faker_form, page_title: "Dashboard")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    create_form = AshPhoenix.Form.validate(socket.assigns.create_form, params)
    {:noreply, assign(socket, create_form: create_form)}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.create_form, params: params) do
      {:ok, tenant} ->
        {:ok, _ut} =
          HousingApp.Accounts.UserTenant
          |> Ash.Changeset.for_create(
            :create,
            %{
              tenant_id: tenant.id,
              user_id: socket.assigns.current_user.id,
              user_type: :admin
            },
            actor: socket.assigns.current_user
          )
          |> Ash.Changeset.load([:user, :tenant])
          |> HousingApp.Accounts.create()

        {:noreply,
         socket
         |> put_flash(:info, "Saved tenant for #{tenant.name}!")
         |> push_navigate(to: ~p"/switch-tenant/#{tenant.id}")}

      {:error, create_form} ->
        {:noreply, assign(socket, create_form: create_form)}
    end
  end

  def handle_event("validate-faker", _form, socket) do
    {:noreply, socket}
  end

  def handle_event("submit-faker", params, socket) do
    Task.async(fn ->
      HousingApp.Faker.generate(
        params,
        tenant: socket.assigns.current_tenant,
        actor: socket.assigns.current_user_tenant
      )
    end)

    {:noreply, put_flash(socket, :info, "Generating fake data...")}
  end

  def handle_info({ref, ret}, socket) do
    Process.demonitor(ref, [:flush])

    case ret do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Generated fake data!")}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, "Error generating fake data: #{inspect(error)}")}
    end
  end
end
