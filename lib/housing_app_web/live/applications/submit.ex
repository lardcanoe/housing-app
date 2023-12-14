defmodule HousingAppWeb.Live.Applications.Submit do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :submit} = assigns) do
    ~H"""
    <.json_form form={@form} json_schema={@json_schema} />
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
        json_schema = app.form.json_schema |> Jason.decode!()

        {:ok,
         assign(socket,
           application_id: app.id,
           json_schema: json_schema,
           form: %{} |> to_form(),
           sidebar: :applications,
           page_title: "Submit Application"
         )}
    end
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "submit",
        data,
        %{assigns: %{application_id: application_id, current_user_tenant: current_user_tenant, current_tenant: tenant}} =
          socket
      ) do
    data = HousingApp.Utils.JsonSchema.cast_params(socket.assigns.json_schema, data)

    ref_schema = ExJsonSchema.Schema.resolve(socket.assigns.json_schema)

    case ExJsonSchema.Validator.validate(ref_schema, data) do
      :ok ->
        case HousingApp.Management.ApplicationSubmission.submit(
               %{application_id: application_id, data: data},
               actor: current_user_tenant,
               tenant: tenant
             ) do
          {:error, errors} ->
            IO.inspect(errors)

            {:noreply,
             socket
             |> assign(form: data |> to_form())
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
         |> assign(form: data |> to_form())
         |> put_flash(:error, "Errors present in form submission.")}
    end
  end
end
