defmodule HousingAppWeb.Live.Forms.View do
  @moduledoc false
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :view} = assigns) do
    ~H"""
    <.json_form form={@form} json_schema={@json_schema} />
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Management.Form.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :forms)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/forms")}

      {:ok, form} ->
        {:ok,
         assign(socket,
           form_id: id,
           json_schema: Jason.decode!(form.json_schema),
           form: to_form(%{}, as: "submit-form"),
           sidebar: :forms,
           page_title: "View Form"
         )}
    end
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", data, %{assigns: %{form_id: form_id}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    data = HousingApp.Utils.JsonSchema.cast_params(socket.assigns.json_schema, data)

    ref_schema = ExJsonSchema.Schema.resolve(socket.assigns.json_schema)

    case ExJsonSchema.Validator.validate(ref_schema, data) do
      :ok ->
        case HousingApp.Management.FormSubmission.submit(%{form_id: form_id, data: data},
               actor: current_user_tenant,
               tenant: tenant
             ) do
          {:error, errors} ->
            IO.inspect(errors)

            {:noreply,
             socket
             |> assign(form: to_form(data))
             |> put_flash(:error, "Error submitting")}

          {:ok, _submission} ->
            {:noreply,
             socket
             |> put_flash(:info, "Thank you for your submission!")
             |> push_navigate(to: ~p"/forms")}
        end

      {:error, errors} ->
        IO.inspect(errors)

        {:noreply,
         socket
         |> assign(form: to_form(data))
         |> put_flash(:error, "Errors present in form submission.")}
    end
  end
end
