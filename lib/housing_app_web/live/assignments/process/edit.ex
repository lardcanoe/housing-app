defmodule HousingAppWeb.Live.Assignments.Process.Form do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(assigns) do
    ~H"""
    <.simple_form autowidth={false} class="max-w-4xl" for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">
        <span :if={@ash_form.source.action == :update}>Edit Process</span>
        <span :if={@ash_form.source.action == :new}>New Process</span>
      </h2>

      <.input field={@ash_form[:name]} label="Name" />
      <.input field={@ash_form[:description]} label="Description" />
      <.input
        type="select"
        field={@ash_form[:process]}
        options={@selection_process_options}
        label="Process"
        prompt="Select a type..."
        required
      />
      <!-- Cannot get the SortableJS to ignore hidden inputs, so we need to put here instead -->
      <.inputs_for :let={join_form} field={@ash_form[:criterion]}>
        <%= hidden_input(join_form, :index) %>
      </.inputs_for>

      <h3 class="mb-4 text-lg font-bold text-gray-900 dark:text-white">Rules (in order of execution)</h3>
      <div id={"#{@ash_form.name}-steps"} phx-hook="SortableList" data-list_id={@ash_form.name}>
        <.inputs_for :let={join_form} field={@ash_form[:criterion]} skip_hidden={true}>
          <div
            data-index={AshPhoenix.Form.value(join_form, :index)}
            class="
            text-gray-900 dark:text-white
            draggable
            drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0
          drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0"
          >
            <div class="flex space-x-4 drag-ghost:opacity-0">
              <.icon name="hero-bars-3-solid" class="w-6 h-6 mt-4 drag-handle" />
              <div class="w-full">
                <.input type="select" options={@criteria_options} field={join_form[:criteria_id]} />
              </div>
              <div class="pt-3">
                <.button
                  type="button"
                  class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-xs dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
                  phx-click="remove-form"
                  phx-value-path={join_form.name}
                >
                  Remove
                </.button>
              </div>
            </div>
          </div>
        </.inputs_for>
      </div>
      <div class="mb-5" phx-feedback-for={@ash_form[:criterion].name}>
        <.error :for={msg <- Enum.map(@ash_form[:criterion].errors, &translate_error(&1))}><%= msg %></.error>
      </div>

      <.button type="button" phx-click="add-criteria" phx-value-path={@ash_form[:criterion].name}>
        Add Criteria
      </.button>

      <div class="block mt-4">
        <.button>
          <span :if={@ash_form.source.action == :update}>Update Process</span>
          <span :if={@ash_form.source.action == :new}>Create Process</span>
        </.button>
      </div>
    </.simple_form>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Assignments.SelectionProcess.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :assignments)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/assignments/processes")}

      {:ok, process} ->
        ash_form =
          process
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
           criteria_options: criteria_options(current_user_tenant, tenant),
           selection_process_options: selection_process_options(),
           sidebar: :assignments,
           page_title: "Edit Selection Process"
         )}
    end
  end

  def mount(_params, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    ash_form =
      HousingApp.Assignments.SelectionProcess
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
       criteria_options: criteria_options(current_user_tenant, tenant),
       selection_process_options: selection_process_options(),
       sidebar: :assignments,
       page_title: "New Selection Process"
     )}
  end

  def handle_event("add-criteria", %{"path" => path}, socket) do
    %{criteria_options: criteria_options, ash_form: ash_form} = socket.assigns

    if Enum.empty?(criteria_options) do
      {:noreply, socket}
    else
      {_, id} = hd(criteria_options)

      current_index =
        (ash_form.source.forms[:criterion] || [])
        |> Enum.map(&AshPhoenix.Form.value(&1, :index))
        |> Enum.max(fn -> -1 end)

      ash_form =
        AshPhoenix.Form.add_form(socket.assigns.ash_form, path,
          params: %{"criteria_id" => id, "index" => current_index + 1}
        )

      {:noreply, assign(socket, ash_form: ash_form)}
    end
  end

  def handle_event("remove-form", %{"path" => path}, socket) do
    ash_form = AshPhoenix.Form.remove_form(socket.assigns.ash_form, path)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("reposition", %{"new" => new_position, "old" => old_position}, socket) do
    ash_form = socket.assigns.ash_form

    updated_criterion_params =
      ash_form.source.forms[:criterion]
      |> Enum.map(fn join_form ->
        remap_join_form(join_form, new_position, old_position)
      end)
      |> Enum.sort_by(& &1["index"])
      |> Enum.reduce(%{}, fn form, acc ->
        Map.put(acc, Integer.to_string(form["index"]), form)
      end)

    params =
      ash_form
      |> AshPhoenix.Form.params()
      |> Map.put("criterion", updated_criterion_params)

    ash_form = AshPhoenix.Form.validate(ash_form, params)

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
         |> put_flash(:info, "Successfully saved process.")
         |> push_navigate(to: ~p"/assignments/processes")}

      {:error, ash_form} ->
        dbg(ash_form)
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end

  defp criteria_options(current_user_tenant, tenant) do
    [actor: current_user_tenant, tenant: tenant]
    |> HousingApp.Assignments.SelectionCriteria.list!()
    |> Enum.map(fn cq -> {cq.name, cq.id} end)
  end

  defp remap_join_form(join_form, new_position, old_position) do
    updated_index =
      HousingApp.Utils.Forms.update_position(AshPhoenix.Form.value(join_form, :index), new_position, old_position)

    Map.merge(AshPhoenix.Form.params(join_form), %{
      "index" => updated_index,
      "criteria_id" => AshPhoenix.Form.value(join_form, :criteria_id) || ""
    })
  end
end
