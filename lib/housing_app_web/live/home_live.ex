defmodule HousingAppWeb.Live.HomeLive do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
      <div class="border-2 border-dashed border-gray-300 rounded-lg dark:border-gray-600 h-32 md:h-64">
        <.button>Hello</.button>
      </div>
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
    <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-96 mb-4"></div>
    <div class="grid grid-cols-2 gap-4 mb-4">
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-48 md:h-72"></div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-48 md:h-72"></div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-48 md:h-72"></div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-48 md:h-72"></div>
    </div>
    <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-96 mb-4"></div>
    <div class="grid grid-cols-2 gap-4">
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-48 md:h-72"></div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-48 md:h-72"></div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-48 md:h-72"></div>
      <div class="border-2 border-dashed rounded-lg border-gray-300 dark:border-gray-600 h-48 md:h-72"></div>
    </div>
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

  def handle_event("submit", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.create_form, params: params) do
      {:ok, tenant} ->
        {:noreply,
         socket
         |> put_flash(:info, "Saved tenant for #{tenant.name}!")
         |> push_navigate(to: ~p"/")}

      {:error, create_form} ->
        {:noreply, assign(socket, create_form: create_form)}
    end
  end
end
