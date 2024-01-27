defmodule HousingAppWeb.Live.Assignments.Criteria.Form do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(assigns) do
    ~H"""
    <.simple_form autowidth={false} class="max-w-4xl" for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">
        <span :if={@ash_form.source.action == :update}>Edit Criteria</span>
        <span :if={@ash_form.source.action == :new}>New Criteria</span>
      </h2>

      <.input field={@ash_form[:name]} label="Name" />
      <.input field={@ash_form[:description]} label="Description" />

      <h3 class="mb-4 text-lg font-bold text-gray-900 dark:text-white">Conditions</h3>
      <.inputs_for :let={cond_form} field={@ash_form[:conditions]}>
        <div class="space-y-4 md:flex md:space-y-0 md:space-x-4">
          <div class="w-full">
            <.input type="select" options={@common_query_options} field={cond_form[:common_query_id]} label="Query" />
          </div>
          <div class="pt-7">
            <.button
              type="button"
              class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-xs dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
              phx-click="remove-form"
              phx-value-path={cond_form.name}
            >
              Remove
            </.button>
          </div>
        </div>
      </.inputs_for>

      <.button type="button" phx-click="add-query" phx-value-path={@ash_form[:conditions].name}>
        <span :if={Enum.any?(AshPhoenix.Form.value(@ash_form, :conditions))}>Add Additional Condition</span>
        <span :if={Enum.empty?(AshPhoenix.Form.value(@ash_form, :conditions))}>Add Condition</span>
      </.button>

      <h3 class="mb-4 mt-4 text-lg font-bold text-gray-900 dark:text-white">Filters</h3>
      <.inputs_for :let={filter_form} field={@ash_form[:filters]}>
        <div class="space-y-4 md:flex md:space-y-0 md:space-x-4">
          <div class="w-full">
            <.input type="select" options={@common_query_options} field={filter_form[:common_query_id]} label="Query" />
          </div>
          <div class="pt-7">
            <.button
              type="button"
              class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-xs dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
              phx-click="remove-form"
              phx-value-path={filter_form.name}
            >
              Remove
            </.button>
          </div>
        </div>
      </.inputs_for>

      <.button type="button" phx-click="add-query" phx-value-path={@ash_form[:filters].name}>
        <span :if={Enum.any?(AshPhoenix.Form.value(@ash_form, :filters))}>Add Additional Filter</span>
        <span :if={Enum.empty?(AshPhoenix.Form.value(@ash_form, :filters))}>Add Filter</span>
      </.button>

      <div class="block mt-4">
        <.button>
          <span :if={@ash_form.source.action == :update}>Update Criteria</span>
          <span :if={@ash_form.source.action == :new}>Create Criteria</span>
        </.button>
      </div>
    </.simple_form>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Assignments.SelectionCriteria.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :assignments)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/assignments/criteria")}

      {:ok, criteria} ->
        ash_form =
          criteria
          |> AshPhoenix.Form.for_update(:update,
            api: HousingApp.Assignments,
            forms: [auto?: true],
            actor: current_user_tenant,
            tenant: tenant
          )
          |> to_form()

        {:ok,
         assign(socket,
           ash_form: ash_form,
           common_query_options: common_query_options(current_user_tenant, tenant),
           sidebar: :assignments,
           page_title: "Edit Inventory Criteria"
         )}
    end
  end

  def mount(_params, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    ash_form =
      HousingApp.Assignments.SelectionCriteria
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Assignments,
        forms: [auto?: true],
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    {:ok,
     assign(socket,
       ash_form: ash_form,
       common_query_options: common_query_options(current_user_tenant, tenant),
       sidebar: :assignments,
       page_title: "New Inventory Criteria"
     )}
  end

  def handle_event("add-query", %{"path" => path}, socket) do
    %{common_query_options: common_query_options} = socket.assigns

    if Enum.empty?(common_query_options) do
      {:noreply, socket}
    else
      {_, id} = hd(common_query_options)
      ash_form = AshPhoenix.Form.add_form(socket.assigns.ash_form, path, params: %{"common_query_id" => id})
      {:noreply, assign(socket, ash_form: ash_form)}
    end
  end

  def handle_event("remove-form", %{"path" => path}, socket) do
    ash_form = AshPhoenix.Form.remove_form(socket.assigns.ash_form, path)
    {:noreply, assign(socket, ash_form: ash_form)}
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
         |> put_flash(:info, "Successfully saved criteria.")
         |> push_navigate(to: ~p"/assignments/criteria")}

      {:error, ash_form} ->
        dbg(ash_form)
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end

  defp common_query_options(current_user_tenant, tenant) do
    [actor: current_user_tenant, tenant: tenant]
    |> HousingApp.Management.CommonQuery.list!()
    |> Enum.map(fn cq -> {cq.name, cq.id} end)
  end
end
