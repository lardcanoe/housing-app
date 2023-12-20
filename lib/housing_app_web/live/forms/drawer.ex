defmodule HousingAppWeb.Components.Drawer.Form do
  @moduledoc false

  use HousingAppWeb, :live_component

  import HousingAppWeb.CoreComponents, only: [icon: 1]

  attr :id, :string, required: true
  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true

  def render(%{form: nil} = assigns) do
    ~H"""
    <div class="hidden" id={@id}></div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="text-gray-900 dark:text-white" id={@id}>
      <button
        type="button"
        phx-click={JS.add_class("hidden", to: "##{@id}-parent")}
        class="text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 top-2.5 right-2.5 inline-flex items-center dark:hover:bg-gray-600 dark:hover:text-white"
      >
        <.icon name="hero-x-mark-solid" class="w-5 h-5" />
        <span class="sr-only">Close menu</span>
      </button>

      <div class="flex items-center mb-4 sm:mb-5">
        <.icon name="hero-document-text-solid" class="w-12 h-12" />
        <div>
          <h4 id="drawer-label" class="mb-1 text-xl font-bold leading-none text-gray-900 dark:text-white">
            <%= @form.name %>
          </h4>
          <p :if={!is_nil(@form.description) && @form.description != ""} class="text-base text-gray-500 dark:text-gray-400">
            <%= @form.description %>
          </p>
        </div>
      </div>
      <dl>
        <dt
          :if={@current_user_tenant.user.role == :platform_admin}
          class="mb-2 font-semibold leading-none text-gray-900 dark:text-white"
        >
          Id
        </dt>
        <dd
          :if={@current_user_tenant.user.role == :platform_admin}
          class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400"
        >
          <%= @form.id %>
        </dd>
        <dt class="mb-2 font-semibold leading-none text-gray-900 dark:text-white">Status</dt>
        <dd class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400"><%= @form.status %></dd>
      </dl>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket |> assign(form: nil)}
  end

  def update(
        %{form_id: form_id},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    case HousingApp.Management.Form.get_by_id(form_id, actor: current_user_tenant, tenant: tenant) do
      {:ok, form} ->
        {:ok, assign(socket, form: form)}

      {:error, _} ->
        {:ok, assign(socket, form: nil)}
    end
  end

  def update(params, socket) do
    {:ok, assign(socket, params)}
  end
end
