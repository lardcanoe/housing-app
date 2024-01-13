defmodule HousingAppWeb.Live.Forms.Edit do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2">
      <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit" autowidth={false}>
        <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update form</h2>
        <.input field={@ash_form[:name]} label="Name" />
        <.input type="textarea" rows="20" field={@ash_form[:json_schema]} label="Schema" />
        <.input type="select" options={@status_options} field={@ash_form[:status]} label="Status" />
        <.input field={@ash_form[:type]} label="Type" />
        <:actions>
          <.button>Save</.button>
          <.button :if={false} type="delete">Delete</.button>
        </:actions>
      </.simple_form>
      <div>
        <h3 class="mb-4 font-bold text-gray-900 dark:text-white">Example form:</h3>
        <div class="p-4">
          <.json_form form={@schema_form} json_schema={@json_schema} embed={true} add_custom_root={false} />
        </div>
      </div>
    </div>
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
        ash_form =
          form
          |> AshPhoenix.Form.for_update(:update,
            api: HousingApp.Management,
            forms: [auto?: true],
            actor: current_user_tenant,
            tenant: tenant
          )
          |> to_form()

        {:ok,
         assign(socket,
           ash_form: ash_form,
           schema_form: to_form(%{"schema" => %{}}, as: "schema"),
           json_schema: Jason.decode!(form.json_schema),
           status_options: status_options(),
           sidebar: :forms,
           page_title: "Edit Form"
         )}
    end
  end

  def handle_event("validate", %{"_target" => ["form", "json_schema"], "form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form, json_schema: Jason.decode!(params["json_schema"]))}
  rescue
    Jason.DecodeError ->
      {:noreply, socket}
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
         |> put_flash(:info, "Successfully updated the form.")
         |> push_navigate(to: ~p"/forms")}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
