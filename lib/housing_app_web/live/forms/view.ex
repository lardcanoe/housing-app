defmodule HousingAppWeb.Live.Forms.View do
  @moduledoc false
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :view} = assigns) do
    ~H"""
    <div class="bg-white dark:bg-white">
      <div id="json-schema-form" phx-hook="JSONSchemaForm" />
      <.button id="json-schema-form-submit" phx-update="ignore">
        Save
      </.button>
    </div>
    """
  end

  def mount(
        %{"id" => id},
        _session,
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    case HousingApp.Management.Form.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/forms")}

      {:ok, form} ->
        {:ok, assign(socket, form_id: id, json_schema: form.json_schema |> Jason.decode!(), page_title: "View Form")}
    end
  end

  def handle_event("load-schema", _params, socket) do
    {:reply, %{schema: socket.assigns.json_schema}, socket}
  end

  def handle_event(
        "submit",
        data,
        %{assigns: %{form_id: form_id, current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    ref_schema = ExJsonSchema.Schema.resolve(socket.assigns.json_schema)

    case ExJsonSchema.Validator.validate(ref_schema, data) do
      :ok ->
        case HousingApp.Management.FormSubmission.submit(%{form_id: form_id, data: data},
               actor: current_user_tenant,
               tenant: tenant
             ) do
          {:error, errors} ->
            IO.inspect(errors)
            {:noreply, socket |> put_flash(:error, "Error submitting")}

          {:ok, _submission} ->
            {:noreply,
             socket
             |> put_flash(:info, "Thank you for your submission!")
             |> push_navigate(to: ~p"/forms")}
        end

      {:error, errors} ->
        IO.inspect(errors)
        # |> put_flash(:error, "Errors present in form submission.")}
        {:noreply, socket}
    end
  end
end
