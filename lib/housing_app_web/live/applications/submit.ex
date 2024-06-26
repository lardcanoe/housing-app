defmodule HousingAppWeb.Live.Applications.Submit do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  require Logger

  def render(%{live_action: :submit, multi_step: true, current_user_tenant: %{user_type: :user}} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white"><%= @application.name %></h1>
    <div class="md:flex">
      <ol class="space-y-4 w-72 flex-column pr-8">
        <li :for={step <- @application.steps |> Enum.sort_by(& &1.step)}>
          <div
            class={[
              @current_step.id == step.id &&
                "w-full p-4 text-blue-700 bg-blue-100 border border-blue-300 rounded-lg dark:bg-gray-800 dark:border-blue-800 dark:text-blue-400",
              @current_step.id != step.id && !MapSet.member?(@completed_steps, step.id) &&
                "w-full p-4 text-gray-900 bg-gray-100 border border-gray-300 rounded-lg dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400",
              @current_step.id != step.id && MapSet.member?(@completed_steps, step.id) &&
                "w-full p-4 text-green-700 border border-green-300 rounded-lg bg-green-50 dark:bg-gray-800 dark:border-green-800 dark:text-green-400"
            ]}
            role="alert"
            phx-click="navigate"
            phx-value-field="step"
            phx-value-id={step.id}
            style={@current_step.id != step.id && MapSet.member?(@completed_steps, step.id) && "cursor: pointer"}
          >
            <div class="flex items-center justify-between">
              <span class="sr-only"><%= step.title %></span>
              <h3 class="font-medium"><%= step.step %>. <%= step.title %></h3>
              <svg
                :if={@current_step.id == step.id}
                class="rtl:rotate-180 w-4 h-4"
                aria-hidden="true"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 14 10"
              >
                <path
                  stroke="currentColor"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M1 5h12m0 0L9 1m4 4L9 9"
                />
              </svg>
              <svg
                :if={@current_step.id != step.id && MapSet.member?(@completed_steps, step.id)}
                class="w-4 h-4"
                aria-hidden="true"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 16 12"
              >
                <path
                  stroke="currentColor"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M1 5.917 5.724 10.5 15 1.5"
                />
              </svg>
            </div>
          </div>
        </li>
      </ol>

      <.live_component
        :if={@component}
        module={@component}
        id="step-component"
        data={@step_data}
        submission={@submission}
        application_step={@current_step}
        current_user_tenant={@current_user_tenant}
        current_tenant={@current_tenant}
      >
      </.live_component>

      <.simple_form :if={@json_schema} autowidth={false} for={@form} phx-change="validate" phx-submit="submit-next">
        <.json_form
          form={@data_form}
          json_schema={@json_schema}
          embed={true}
          prefix="form"
          add_custom_root={true}
          variables={@variables}
          actor={@current_user_tenant}
          tenant={@current_tenant}
        />
        <:actions>
          <.button :if={@current_step.id == @last_step_id}>Submit</.button>
          <.button :if={@current_step.id != @last_step_id}>Next</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def render(%{live_action: :submit} = assigns) do
    ~H"""
    <.simple_form for={@form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white"><%= @application.name %></h2>
      <.async_result :let={profiles} :if={@current_user_tenant.user_type != :user} assign={@profiles}>
        <:loading>
          <.input
            type="select"
            field={@form[:profile_id]}
            options={[]}
            label="Profile"
            prompt="Loading profiles..."
            disabled
          />
        </:loading>
        <:failed :let={reason}><%= reason %></:failed>
        <.input
          type="select"
          field={@form[:profile_id]}
          options={profiles}
          label="Profile"
          prompt="Select a profile..."
          required
        />
      </.async_result>

      <.json_form form={@data_form} json_schema={@json_schema} embed={true} prefix="form" />

      <:actions>
        <.button>Submit</.button>
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
        if app.steps != [] do
          step = Enum.find(app.steps, &(&1.step == 1))

          last_step_id = app.steps |> Enum.sort(&(&1.step > &2.step)) |> hd() |> then(& &1.id)

          {:ok,
           socket
           |> assign(
             application: app,
             multi_step: true,
             current_step: step,
             last_step_id: last_step_id,
             form: to_form(%{"data" => %{}}, as: "form"),
             sidebar: :applications,
             page_title: "Submit Application"
           )
           |> load_form()
           |> load_current_step()
           |> load_step_submission()
           |> load_completed_step_submissions()
           |> load_async_assigns()}
        else
          {:ok,
           socket
           |> assign(
             application: app,
             json_schema: Jason.decode!(app.form.json_schema),
             multi_step: false,
             form: to_form(%{"profile_id" => "", "data" => %{}}, as: "form"),
             sidebar: :applications,
             page_title: "Submit Application"
           )
           |> load_form()
           |> load_async_assigns()}
        end
    end
  end

  def load_form(%{assigns: %{application: %{submission_type: :many} = application}} = socket) do
    # FUTURE: Should really find most recent, and if :started, then continue it
    socket
    |> assign(
      step_data: %{},
      data_form: to_form(%{"profile_id" => "", "data" => %{}}, as: "data")
    )
    |> stub_new_submission(application)
  end

  def load_form(%{assigns: %{application: application}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Management.ApplicationSubmission.get_submission(application.id, current_user_tenant.id,
           actor: current_user_tenant,
           tenant: tenant
         ) do
      {:ok, submission} ->
        assign(socket, submission: submission, data_form: to_form(%{"data" => submission.data}, as: "data"))

      {:error, _} ->
        socket
        |> stub_new_submission(application)
        |> assign(data_form: to_form(%{"profile_id" => "", "data" => %{}}, as: "data"))
    end
  end

  defp stub_new_submission(socket, application) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    {:ok, submission} =
      HousingApp.Management.ApplicationSubmission.start(
        %{application_id: application.id},
        actor: current_user_tenant,
        tenant: tenant
      )

    assign(socket, submission: submission)
  end

  def load_async_assigns(%{assigns: %{current_user_tenant: %{user_type: :user}}} = socket) do
    socket
  end

  def load_async_assigns(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    if connected?(socket) do
      assign_async(socket, [:profiles], fn ->
        profiles =
          [actor: current_user_tenant, tenant: tenant]
          |> HousingApp.Management.Profile.list!()
          |> Enum.sort_by(& &1.user_tenant.user.name)
          |> Enum.map(&{&1.user_tenant.user.name, &1.id})

        {:ok, %{profile: nil, profiles: profiles}}
      end)
    else
      assign_async(socket, [:profiles], fn ->
        {:ok, %{profile: nil, profiles: []}}
      end)
    end
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"form" => %{"data" => json_data}} = form, %{assigns: %{submission: submission}} = socket)
      when not is_nil(submission) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    json_data = HousingApp.Utils.JsonSchema.cast_params(socket.assigns.json_schema, json_data)

    ref_schema = ExJsonSchema.Schema.resolve(socket.assigns.json_schema)

    actor = get_actor(current_user_tenant, tenant, form)

    case ExJsonSchema.Validator.validate(ref_schema, json_data) do
      :ok ->
        case HousingApp.Management.ApplicationSubmission.resubmit(submission, %{data: json_data},
               actor: actor,
               tenant: tenant
             ) do
          {:error, errors} ->
            IO.inspect(errors)

            {:noreply,
             socket
             |> assign(form: to_form(form))
             |> put_flash(:error, "Error resubmitting")}

          {:ok, _submission} ->
            {:noreply,
             socket
             |> put_flash(:info, "Thank you for updating submission!")
             |> push_navigate(to: ~p"/applications")}
        end

      {:error, errors} ->
        IO.inspect(errors)

        {:noreply,
         socket
         |> assign(form: to_form(form))
         |> put_flash(:error, "Errors present in form submission.")}
    end
  end

  def handle_event(
        "submit",
        %{"form" => %{"data" => json_data}} = form,
        %{assigns: %{application: application}} = socket
      ) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    json_data = HousingApp.Utils.JsonSchema.cast_params(socket.assigns.json_schema, json_data)

    ref_schema = ExJsonSchema.Schema.resolve(socket.assigns.json_schema)

    actor = get_actor(current_user_tenant, tenant, form)

    case ExJsonSchema.Validator.validate(ref_schema, json_data) do
      :ok ->
        case HousingApp.Management.ApplicationSubmission.submit(
               %{application_id: application.id, status: :completed, data: json_data},
               actor: actor,
               tenant: tenant
             ) do
          {:error, errors} ->
            IO.inspect(errors)

            {:noreply,
             socket
             |> assign(form: to_form(form))
             |> put_flash(:error, "Error submitting")}

          {:ok, _submission} ->
            {:noreply,
             socket
             |> put_flash(:info, "Thank you for your submission!")
             |> push_navigate(to: ~p"/applications")}
        end

      {:error, errors} ->
        IO.inspect(errors)

        {:noreply,
         socket
         |> assign(form: to_form(form))
         |> put_flash(:error, "Errors present in form submission.")}
    end
  end

  def handle_event("navigate", %{"field" => "step", "id" => id}, socket) do
    %{application: application, completed_steps: completed_steps} = socket.assigns

    completed? = MapSet.member?(completed_steps, id)
    step = Enum.find(application.steps, &(&1.id == id))
    prev_step = Enum.find(application.steps, &(&1.step == step.step - 1))

    if prev_step do
      prev_completed? = MapSet.member?(completed_steps, prev_step.id)

      if completed? or prev_completed? do
        {:noreply,
         socket
         |> assign(current_step: step)
         |> load_current_step()
         |> load_step_submission()}
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("submit-next", %{"form" => %{"data" => json_data}}, socket) do
    %{
      current_step: current_step,
      application: application,
      submission: submission,
      completed_steps: completed_steps,
      current_user_tenant: current_user_tenant,
      current_tenant: tenant
    } = socket.assigns

    update_step_submission(socket, json_data)

    completed_steps = MapSet.put(completed_steps, current_step.id)

    case Enum.find(application.steps, &(&1.step == current_step.step + 1)) do
      nil ->
        HousingApp.Management.ApplicationSubmission.resubmit(
          submission,
          %{status: :completed},
          actor: current_user_tenant,
          tenant: tenant
        )

        HousingApp.Management.Service.new_notification(
          "Application submitted",
          "Thank you for your submission. We will review your application shortly.",
          %{action: "submit", resource: "application_submission", resource_id: submission.id},
          actor: current_user_tenant,
          tenant: tenant
        )

        {:noreply,
         socket
         |> put_flash(:info, "Thank you for your submission!")
         |> push_navigate(to: ~p"/applications")}

      next_step ->
        {:noreply,
         socket
         |> assign(
           current_step: next_step,
           completed_steps: completed_steps
         )
         |> load_current_step()
         |> load_step_submission()}
    end
  end

  # When the form has no data, we need to submit an empty map, such as when displaying a message
  def handle_event("submit-next", %{}, socket) do
    handle_event("submit-next", %{"form" => %{"data" => %{}}}, socket)
  end

  def handle_info({:component_submit, data}, socket) do
    handle_event("submit-next", %{"form" => %{"data" => data}}, socket)
  end

  defp load_current_step(socket) do
    %{current_step: current_step} = socket.assigns

    cond do
      current_step.form ->
        socket
        |> assign(
          json_schema: Jason.decode!(current_step.form.json_schema),
          component: nil
        )
        |> load_step_variables()

      current_step.component ->
        assign(socket, component: component_to_module(current_step.component), json_schema: nil, variables: nil)

      true ->
        Logger.error("Step has no form or component")
        assign(socket, component: nil, json_schema: nil, variables: nil)
    end
  end

  defp component_to_module(:assignments_select_bed), do: HousingAppWeb.Components.Assignments.SelectBed
  defp component_to_module(:management_update_profile), do: HousingAppWeb.Components.Management.UpdateProfile

  defp load_step_variables(socket) do
    %{current_step: current_step} = socket.assigns

    # TODO: Only load profile if the form needs it for mustache display
    profile = get_latest_profile(socket)

    variables =
      Map.put(
        HousingApp.Utils.MapUtil.array_to_map(current_step.form.variables),
        "profile",
        profile.sanitized_data
      )

    assign(socket, variables: variables)
  end

  defp load_step_submission(socket) do
    %{
      submission: submission,
      current_step: current_step,
      current_user_tenant: current_user_tenant,
      current_tenant: tenant
    } = socket.assigns

    case HousingApp.Management.ApplicationStepSubmission.get_by_step_id(submission.id, current_step.id,
           actor: current_user_tenant,
           tenant: tenant
         ) do
      {:ok, step_submission} ->
        assign(socket,
          step_submission: step_submission,
          step_data: step_submission.data,
          data_form: to_form(%{"data" => step_submission.data}, as: "data")
        )

      {:error, %Ash.Error.Query.NotFound{}} ->
        assign(socket, step_submission: nil, step_data: %{}, data_form: to_form(%{"data" => %{}}, as: "data"))

      {:error, error} ->
        dbg(error)
        assign(socket, step_submission: nil, step_data: %{}, data_form: to_form(%{"data" => %{}}, as: "data"))
    end
  end

  defp load_completed_step_submissions(socket) do
    %{
      assigns: %{
        submission: submission,
        current_user_tenant: current_user_tenant,
        current_tenant: tenant
      }
    } = socket

    completed_steps =
      submission.id
      |> HousingApp.Management.ApplicationStepSubmission.list_by_application_submission!(
        actor: current_user_tenant,
        tenant: tenant
      )
      |> MapSet.new(& &1.step_id)

    assign(socket, completed_steps: completed_steps)
  end

  defp update_step_submission(
         %{assigns: %{current_step: current_step, step_submission: step_submission}} = socket,
         json_data
       )
       when not is_nil(step_submission) and current_step.id == step_submission.step_id do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    HousingApp.Management.ApplicationStepSubmission.resubmit(
      step_submission,
      %{data: json_data},
      actor: current_user_tenant,
      tenant: tenant
    )
  end

  defp update_step_submission(socket, json_data) do
    %{
      assigns: %{
        submission: submission,
        current_step: current_step,
        current_user_tenant: current_user_tenant,
        current_tenant: tenant
      }
    } = socket

    HousingApp.Management.ApplicationStepSubmission.submit(
      %{application_submission_id: submission.id, step_id: current_step.id, data: json_data},
      actor: current_user_tenant,
      tenant: tenant
    )
  end

  defp get_actor(current_user_tenant, tenant, form) do
    case current_user_tenant.user_type do
      :user ->
        current_user_tenant

      _ ->
        # TODO: Validation
        form["form"]["profile_id"]
        |> HousingApp.Management.Profile.get_by_id!(
          actor: current_user_tenant,
          tenant: tenant
        )
        |> then(& &1.user_tenant)
    end
  end

  defp get_latest_profile(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    HousingApp.Management.Profile.get_mine!(
      actor: current_user_tenant,
      tenant: tenant
    )
  end
end
