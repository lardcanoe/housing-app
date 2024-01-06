defmodule HousingAppWeb.Components.Settings.Queries do
  @moduledoc false

  use HousingAppWeb, :live_component

  import HousingAppWeb.CoreComponents

  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true

  def render(%{user_form: nil} = assigns) do
    ~H"""
    <div class="hidden"></div>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        autowidth={false}
        class="mt-4"
        for={@user_form}
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
      >
        <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Query</h2>
        <.input field={@user_form[:name]} label="Name" />
        <div
          id="query-builder"
          name="form[query]"
          class="mb-4"
          phx-hook="QueryBuilder"
          phx-update="ignore"
          data-query={@query}
          data-fields={@fields}
          data-phoenix-target={@myself}
        />

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
       user_form: to_form(%{}, as: "form"),
       query: Jason.encode!(%{combinator: "", rules: []}),
       fields: Jason.encode!([%{name: "firstName", label: "First Name"}, %{name: "lastName", label: "Last Name"}])
     )}
  end

  def handle_event("query-changed", _data, socket) do
    {:noreply, socket}
  end

  def handle_event("validate", _data, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"form" => data}, socket) do
    %{current_user_tenant: current_user_tenant} = socket.assigns

    case HousingApp.Accounts.Service.invite_user_to_tenant(data["email"], data["name"], data["user_type"],
           actor: current_user_tenant
         ) do
      {:ok, _ut} ->
        {:noreply,
         assign(socket,
           user_form: to_form(%{}, as: "form"),
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
