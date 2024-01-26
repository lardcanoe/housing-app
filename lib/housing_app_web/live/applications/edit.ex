defmodule HousingAppWeb.Live.Applications.Edit do
  @moduledoc false
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit" autowidth={false} class="max-w-4xl mx-auto">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update application</h2>
      <.input field={@ash_form[:name]} label="Name" />
      <.input field={@ash_form[:description]} label="Description" />
      <.input type="select" options={@forms} field={@ash_form[:form_id]} label="Form" prompt="Select a form..." />
      <.input type="select" options={@time_periods} field={@ash_form[:time_period_id]} label="Time Period" />
      <.input type="select" options={@status_options} field={@ash_form[:status]} label="Status" />
      <.input field={@ash_form[:type]} label="Type" />
      <.input type="select" options={@submission_types} field={@ash_form[:submission_type]} label="Submission Type" />

      <p class="required block mb-2 text-lg font-medium text-gray-900 dark:text-white">
        Workflow Steps
      </p>
      <!-- Cannot get the SortableJS to ignore hidden inputs, so we need to put here instead -->
      <.inputs_for :let={step_form} field={@ash_form[:steps]}>
        <%= hidden_input(step_form, :step) %>
      </.inputs_for>

      <div id={"#{@ash_form.name}-steps"} phx-hook="SortableList" data-list_id={@ash_form.name}>
        <.inputs_for :let={step_form} field={@ash_form[:steps]} skip_hidden={true}>
          <div
            data-id={AshPhoenix.Form.value(step_form, :id)}
            class="
            text-gray-900 dark:text-white
            draggable
            drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0
          drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0"
          >
            <div class="flex space-x-4 drag-ghost:opacity-0">
              <.icon name="hero-bars-3-solid" class="w-6 h-6 mt-8 drag-handle" />
              <.input field={step_form[:title]} label="Title" />
              <.input
                type="select"
                options={@application_step_component_options}
                field={step_form[:component]}
                label="Component"
              />
              <.input type="select" options={[{"-None-", nil}] ++ @forms} field={step_form[:form_id]} label="Form" />
              <div class="mt-8">
                <.input type="checkbox" field={step_form[:required]} label="Required" />
              </div>
              <.button
                type="button"
                class="h-8 mt-8 text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-xs dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
                phx-click="remove-form"
                phx-value-path={step_form.name}
              >
                Remove
              </.button>
            </div>
          </div>
        </.inputs_for>
      </div>

      <.button type="button" phx-click="add-step" phx-value-path={@ash_form[:steps].name} class="mb-4">
        <span :if={Enum.any?(AshPhoenix.Form.value(@ash_form, :steps))}>Add Additional Step</span>
        <span :if={Enum.empty?(AshPhoenix.Form.value(@ash_form, :steps))}>Add Workflow Step</span>
      </.button>

      <p
        :if={Enum.any?(AshPhoenix.Form.value(@ash_form, :conditions))}
        class="required block mb-2 text-lg font-medium text-gray-900 dark:text-white"
      >
        Profile Eligibility Conditions
      </p>

      <.inputs_for :let={cond_form} field={@ash_form[:conditions]}>
        <.input type="select" options={@common_query_options} field={cond_form[:common_query_id]} label="Condition">
          <.button
            type="button"
            class="text-white absolute right-8 bottom-2.5 px-3 py-0.5 bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-xs dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
            phx-click="remove-form"
            phx-value-path={cond_form.name}
          >
            Remove
          </.button>
        </.input>
      </.inputs_for>

      <.button
        :if={Enum.any?(@common_query_options)}
        type="button"
        phx-click="add-condition"
        phx-value-path={@ash_form[:conditions].name}
        class="mb-4"
      >
        <span :if={AshPhoenix.Form.value(@ash_form, :conditions) |> Enum.any?()}>Add Additional Condition</span>
        <span :if={AshPhoenix.Form.value(@ash_form, :conditions) |> Enum.empty?()}>Add Profile Eligibility Condition</span>
      </.button>

      <:actions>
        <.button>Save Application</.button>
        <.button :if={false} type="delete">Delete</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Management.Application.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :applications)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/applications")}

      {:ok, app} ->
        ash_form =
          app
          |> AshPhoenix.Form.for_update(:update,
            api: HousingApp.Management,
            forms: [
              auto?: true
            ],
            actor: current_user_tenant,
            tenant: tenant
          )
          |> to_form()

        common_query_options =
          [actor: current_user_tenant, tenant: tenant]
          |> HousingApp.Management.CommonQuery.list!()
          |> Enum.filter(&(&1.resource == :profile))
          |> Enum.map(fn cq -> {cq.name, cq.id} end)

        {:ok,
         assign(socket,
           ash_form: ash_form,
           forms: all_form_options(current_user_tenant, tenant),
           time_periods: time_period_options(current_user_tenant, tenant),
           status_options: status_options(),
           submission_types: submission_type_options(),
           application_step_component_options: application_step_component_options(),
           common_query_options: common_query_options,
           sidebar: :applications,
           page_title: "Edit Application"
         )}
    end
  end

  # https://hexdocs.pm/ash_phoenix/AshPhoenix.Form.html
  def handle_event("add-condition", %{"path" => path}, socket) do
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

  def handle_event("add-step", %{"path" => path}, socket) do
    ash_form = socket.assigns.ash_form
    next_step = ash_form |> AshPhoenix.Form.value(:steps) |> Enum.count()
    next_step = next_step + 1

    ash_form =
      AshPhoenix.Form.add_form(ash_form, path,
        params: %{"step" => Integer.to_string(next_step), "id" => HousingApp.Utils.Random.uuid()}
      )

    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("reposition", %{"new" => new_position, "old" => old_position}, socket) do
    ash_form = socket.assigns.ash_form

    # Convert from index to offset, since we start steps at 1 (I don't remember why)
    old_position = old_position + 1
    new_position = new_position + 1

    updated_step_params =
      ash_form.source.forms[:steps]
      |> Enum.map(fn step_form ->
        current_step = AshPhoenix.Form.value(step_form, :step)

        current_step =
          if is_binary(current_step) do
            String.to_integer(current_step)
          else
            current_step
          end

        updated_step =
          cond do
            current_step == old_position ->
              new_position

            new_position > old_position and current_step > old_position and current_step <= new_position ->
              current_step - 1

            new_position < old_position and current_step >= new_position and current_step < old_position ->
              current_step + 1

            true ->
              current_step
          end

        required = AshPhoenix.Form.value(step_form, :required)
        component = AshPhoenix.Form.value(step_form, :component)
        component = if not is_nil(component) and is_atom(component), do: Atom.to_string(component), else: component

        Map.merge(AshPhoenix.Form.params(step_form), %{
          "step" => Integer.to_string(updated_step),
          "title" => AshPhoenix.Form.value(step_form, :title) || "",
          "component" =>
            if(is_nil(component) or component == "",
              do: "",
              else: component
            ),
          "required" => if(required == false or required == "false", do: "false", else: "true"),
          "form_id" => AshPhoenix.Form.value(step_form, :form_id) || "",
          "_touched" => "_form_type,_persistent_id,component,form_id,id,required,step,title"
        })
      end)
      |> Enum.sort_by(&String.to_integer(&1["step"]))
      |> Enum.reduce(%{}, fn step, acc ->
        Map.put(acc, Integer.to_string(String.to_integer(step["step"]) - 1), step)
      end)

    params =
      ash_form
      |> AshPhoenix.Form.params()
      |> Map.put("steps", updated_step_params)

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
         |> put_flash(:info, "Successfully updated the application.")
         |> push_navigate(to: ~p"/applications")}

      {:error, ash_form} ->
        IO.inspect(ash_form.source)
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
