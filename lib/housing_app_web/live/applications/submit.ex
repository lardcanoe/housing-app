defmodule HousingAppWeb.Live.Applications.Submit do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :submit, multi_step: true, current_user_tenant: %{user_type: :user}} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white"><%= @application.name %></h1>
    <div class="md:flex">
      <ol class="space-y-4 w-72 flex-column pr-8">
        <li :for={step <- @application.steps}>
          <div
            class="w-full p-4 text-green-700 border border-green-300 rounded-lg bg-green-50 dark:bg-gray-800 dark:border-green-800 dark:text-green-400"
            role="alert"
            phx-click="navigate"
            phx-value-field="step"
            phx-value-id={step.step}
          >
            <div class="flex items-center justify-between">
              <span class="sr-only"><%= step.title %></span>
              <h3 class="font-medium"><%= step.step %>. <%= step.title %></h3>
              <svg class="w-4 h-4" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 16 12">
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

      <.simple_form autowidth={false} for={@form} phx-change="validate" phx-submit="submit-next">
        <.json_form form={@data_form} json_schema={@json_schema} embed={true} prefix="form" />
        <:actions>
          <.button>Next</.button>
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

  def mount(
        %{"id" => id},
        _session,
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    case HousingApp.Management.Application.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :applications)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/applications")}

      {:ok, app} ->
        if app.steps != [] do
          step = app.steps |> Enum.find(&(&1.step == 1))

          {:ok,
           assign(socket,
             application: app,
             json_schema: step.form.json_schema |> Jason.decode!(),
             multi_step: true,
             current_step_id: step.id,
             form: %{"data" => %{}} |> to_form(as: "form"),
             sidebar: :applications,
             page_title: "Submit Application"
           )
           |> load_form(app)
           |> load_step_submission()
           |> load_async_assigns()}
        else
          {:ok,
           assign(socket,
             application: app,
             json_schema: app.form.json_schema |> Jason.decode!(),
             multi_step: false,
             form: %{"profile_id" => "", "data" => %{}} |> to_form(as: "form"),
             sidebar: :applications,
             page_title: "Submit Application"
           )
           |> load_form(app)
           |> load_async_assigns()}
        end
    end
  end

  def load_form(socket, %{submission_type: :many}) do
    socket |> assign(submission: nil, data_form: %{"profile_id" => "", "data" => %{}} |> to_form(as: "data"))
  end

  def load_form(%{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket, application) do
    case HousingApp.Management.ApplicationSubmission.get_submission(application.id, current_user_tenant.id,
           actor: current_user_tenant,
           tenant: tenant
         ) do
      {:ok, submission} ->
        assign(socket, submission: submission, data_form: %{"data" => submission.data} |> to_form(as: "data"))

      {:error, _} ->
        socket
        |> stub_new_submission(application, current_user_tenant, tenant)
        |> assign(data_form: %{"profile_id" => "", "data" => %{}} |> to_form(as: "data"))
    end
  end

  defp stub_new_submission(socket, application, actor, tenant) do
    {:ok, submission} =
      HousingApp.Management.ApplicationSubmission.start(
        %{application_id: application.id},
        actor: actor,
        tenant: tenant
      )

    socket |> assign(submission: submission)
  end

  def load_async_assigns(%{assigns: %{current_user_tenant: %{user_type: :user}}} = socket) do
    socket
  end

  def load_async_assigns(%{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    socket
    |> assign_async([:profiles], fn ->
      profiles =
        HousingApp.Management.Profile.list!(actor: current_user_tenant, tenant: tenant)
        |> Enum.sort_by(& &1.user_tenant.user.name)
        |> Enum.map(&{&1.user_tenant.user.name, &1.id})

      {:ok,
       %{
         profiles: profiles
       }}
    end)
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "submit",
        %{"form" => %{"data" => json_data}} = form,
        %{
          assigns: %{
            submission: submission,
            current_user_tenant: current_user_tenant,
            current_tenant: tenant
          }
        } = socket
      )
      when not is_nil(submission) do
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
             |> assign(form: form |> to_form())
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
         |> assign(form: form |> to_form())
         |> put_flash(:error, "Errors present in form submission.")}
    end
  end

  def handle_event(
        "submit",
        %{"form" => %{"data" => json_data}} = form,
        %{
          assigns: %{
            application: application,
            current_user_tenant: current_user_tenant,
            current_tenant: tenant
          }
        } = socket
      ) do
    json_data = HousingApp.Utils.JsonSchema.cast_params(socket.assigns.json_schema, json_data)

    ref_schema = ExJsonSchema.Schema.resolve(socket.assigns.json_schema)

    actor = get_actor(current_user_tenant, tenant, form)

    case ExJsonSchema.Validator.validate(ref_schema, json_data) do
      :ok ->
        case HousingApp.Management.ApplicationSubmission.submit(
               %{application_id: application.id, data: json_data},
               actor: actor,
               tenant: tenant
             ) do
          {:error, errors} ->
            IO.inspect(errors)

            {:noreply,
             socket
             |> assign(form: form |> to_form())
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
         |> assign(form: form |> to_form())
         |> put_flash(:error, "Errors present in form submission.")}
    end
  end

  def handle_event("navigate", %{"field" => "step", "id" => id}, socket) do
    %{assigns: %{application: application}} = socket
    id = String.to_integer(id)

    step = application.steps |> Enum.find(&(&1.step == id))

    {:noreply,
     socket
     |> assign(
       current_step_id: step.id,
       json_schema: step.form.json_schema |> Jason.decode!(),
       form: %{"data" => %{}} |> to_form(as: "form")
     )}
  end

  def handle_event("submit-next", %{"form" => %{"data" => json_data}}, socket) do
    %{
      assigns: %{
        current_step_id: step_id,
        application: application,
        submission: submission,
        current_user_tenant: current_user_tenant,
        current_tenant: tenant
      }
    } = socket

    step = application.steps |> Enum.find(&(&1.id == step_id))

    update_step_submission(socket, json_data)

    case application.steps |> Enum.find(&(&1.step == step.step + 1)) do
      nil ->
        HousingApp.Management.ApplicationSubmission.resubmit(
          submission,
          %{status: :completed},
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
           current_step_id: next_step.id,
           json_schema: next_step.form.json_schema |> Jason.decode!()
         )
         |> load_step_submission()}
    end
  end

  defp load_step_submission(socket) do
    %{
      assigns: %{
        submission: submission,
        current_step_id: step_id,
        current_user_tenant: current_user_tenant,
        current_tenant: tenant
      }
    } = socket

    case HousingApp.Management.ApplicationStepSubmission.get_by_step_id(submission.id, step_id,
           actor: current_user_tenant,
           tenant: tenant
         ) do
      {:ok, step_submission} ->
        socket
        |> assign(
          step_submission: step_submission,
          data_form: %{"data" => step_submission.data} |> to_form(as: "data")
        )

      {:error, _} ->
        socket
        |> assign(data_form: %{"data" => %{}} |> to_form(as: "data"))
    end
  end

  defp update_step_submission(%{assigns: %{step_submission: step_submission}} = socket, json_data)
       when not is_nil(step_submission) do
    %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket

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
        current_step_id: step_id,
        current_user_tenant: current_user_tenant,
        current_tenant: tenant
      }
    } = socket

    HousingApp.Management.ApplicationStepSubmission.submit(
      %{application_submission_id: submission.id, step_id: step_id, data: json_data},
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
        HousingApp.Management.Profile.get_by_id!(form["form"]["profile_id"],
          actor: current_user_tenant,
          tenant: tenant
        )
        |> then(& &1.user_tenant)
    end
  end
end
