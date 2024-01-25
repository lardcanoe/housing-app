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

      <p
        :if={@ash_form[:steps].value |> Enum.any?()}
        class="required block mb-2 text-lg font-medium text-gray-900 dark:text-white"
      >
        Workflow Steps
      </p>

      <.inputs_for :let={step_form} field={@ash_form[:steps]}>
        <%= hidden_input(step_form, :step) %>
      </.inputs_for>

      <div id={"#{@ash_form.name}-steps"} phx-hook="SortableList" data-list_id={@ash_form.name}>
        <.inputs_for :let={step_form} field={@ash_form[:steps]} skip_hidden={true}>
          <div
            id={"step-" <> AshPhoenix.Form.value(step_form, :id)}
            data-id={AshPhoenix.Form.value(step_form, :id)}
            class="
            text-gray-900 dark:text-white
            drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0
          drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0"
          >
            <div class="flex space-x-4 drag-ghost:opacity-0">
              <.icon name="hero-bars-3-solid" class="w-6 h-6" />
              <.input field={step_form[:title]} label="Title" />
              <.input
                type="select"
                options={@application_step_component_options}
                field={step_form[:component]}
                label="Component"
              />
              <.input type="checkbox" field={step_form[:required]} label="Required" />
              <.input type="select" options={[{"-None-", nil}] ++ @forms} field={step_form[:form_id]} label="Form" />
            </div>
          </div>
        </.inputs_for>
      </div>

      <p
        :if={@ash_form[:conditions].value |> Enum.any?()}
        class="required block mb-2 text-lg font-medium text-gray-900 dark:text-white"
      >
        Profile Eligibility Conditions
      </p>

      <.inputs_for :let={cond_form} field={@ash_form[:conditions]}>
        <.input type="select" options={@common_query_options} field={cond_form[:common_query_id]} label="Condition">
          <.button
            type="button"
            class="text-white absolute right-8 bottom-2.5 px-3 py-0.5 bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-xs dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
            phx-click="remove-condition"
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
        <span :if={@ash_form[:conditions].value |> Enum.any?()}>Add Additional Condition</span>
        <span :if={@ash_form[:conditions].value |> Enum.empty?()}>Add Profile Eligibility Condition</span>
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

  def handle_event("remove-condition", %{"path" => path}, socket) do
    ash_form = AshPhoenix.Form.remove_form(socket.assigns.ash_form, path)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("reposition", %{"id" => step_id, "new" => new_position, "old" => old_position}, socket) do
    ash_form = socket.assigns.ash_form

    # Convert from index to offset, since we start steps at 1 (I don't remember why)
    old_position = old_position + 1
    new_position = new_position + 1

    mapped_steps =
      ash_form
      |> AshPhoenix.Form.value(:steps)
      |> Enum.map(fn step ->
        cond do
          step.id == step_id ->
            %{step | step: new_position}

          new_position > old_position and step.step > old_position and step.step <= new_position ->
            %{step | step: step.step - 1}

          new_position < old_position and step.step >= new_position and step.step < old_position ->
            %{step | step: step.step + 1}

          true ->
            step
        end
      end)
      |> Enum.sort_by(& &1.step)
      |> Enum.reduce(%{}, fn step, acc ->
        Map.put(acc, Integer.to_string(step.step - 1), %{
          "id" => step.id,
          "step" => step.step,
          "title" => step.title,
          "component" => step.component,
          "required" => step.required,
          "form_id" => step.form_id
        })
      end)

    params = HousingApp.Utils.MapUtil.deep_merge(ash_form.params, %{"steps" => mapped_steps})

    ash_form = AshPhoenix.Form.validate(ash_form, params)

    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    # params =
    #   Map.put(
    #     params,
    #     "steps",
    #     Jason.decode!("""
    #     [
    #       {
    #         "id": "fb70646d-4c46-4a07-bd32-5804da5a3663",
    #         "step": 1,
    #         "title": "Welcome",
    #         "form_id": "86dced97-9cd8-4a8d-bbc3-f4e0a4676a8a",
    #         "required": false
    #       },
    #       {
    #         "id": "cf01fa16-9005-4a28-9bcb-c179c0317c29",
    #         "step": 2,
    #         "title": "Profile",
    #         "component": "management_update_profile",
    #         "required": true
    #       },
    #       {
    #         "id": "3c093686-192e-4a25-a2d1-9790ee38dff0",
    #         "step": 3,
    #         "title": "Confirm ADA",
    #         "form_id": "838a331e-93dd-4fb6-8099-0f88e660fbe4",
    #         "required": false
    #       },
    #       {
    #         "id": "dc3ba31e-3fdd-4fc8-bdae-1086191c2c57",
    #         "step": 4,
    #         "title": "Terms and Conditions",
    #         "form_id": "402bed7a-5ad5-4bcd-bbe1-8bdab4c7a61a",
    #         "required": false
    #       },
    #       {
    #         "id": "2db43efa-9010-497a-aff4-77d52f15d857",
    #         "step": 5,
    #         "title": "Living Learning Community",
    #         "form_id": "cbd88d90-9cef-4689-ae1f-027984d4c91d",
    #         "required": false
    #       },
    #       {
    #         "id": "7fa1a393-e250-4135-82c6-0428f96dffb3",
    #         "step": 6,
    #         "title": "About Myself",
    #         "form_id": "77643ea7-e17c-46ba-87c2-7895b8885716",
    #         "required": false
    #       },
    #       {
    #         "id": "4c0d8a99-afb7-46ee-b118-3b60cc0b2ff2",
    #         "step": 7,
    #         "title": "Select Bed",
    #         "component": "assignments_select_bed",
    #         "required": true
    #       },
    #       {
    #         "id": "0a113cda-efcf-41fe-a731-9402eb4b92d3",
    #         "step": 8,
    #         "title": "Finish and submit",
    #         "form_id": "5105c01b-2cb4-4504-a4ae-fb99561d6432",
    #         "required": false
    #       }
    #     ]
    #     """)
    #   )

    # params =
    #   Map.put(params, "steps", [
    #     %{"title" => "Welcome", "step" => 1, "form_id" => "86dced97-9cd8-4a8d-bbc3-f4e0a4676a8a"},
    #     %{"title" => "Profile", "step" => 2, "form_id" => profile_form.id},
    #     %{"title" => "Confirm ADA", "step" => 3, "form_id" => "838a331e-93dd-4fb6-8099-0f88e660fbe4"},
    #     %{"title" => "Terms and Conditions", "step" => 4, "form_id" => "402bed7a-5ad5-4bcd-bbe1-8bdab4c7a61a"},
    #     %{"title" => "Living Learning Community", "step" => 5, "form_id" => "cbd88d90-9cef-4689-ae1f-027984d4c91d"},
    #     %{"title" => "About Myself", "step" => 6, "form_id" => "77643ea7-e17c-46ba-87c2-7895b8885716"},
    #     %{"title" => "Finish and submit", "step" => 7, "form_id" => "5105c01b-2cb4-4504-a4ae-fb99561d6432"}
    #   ])

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
