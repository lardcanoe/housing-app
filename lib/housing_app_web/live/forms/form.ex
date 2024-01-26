defmodule HousingAppWeb.Live.Forms.Edit do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2">
      <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit" autowidth={false}>
        <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">
          <span :if={@live_action == :edit}>Update form</span>
          <span :if={@live_action == :new}>New form</span>
        </h2>
        <.input field={@ash_form[:name]} label="Name" />
        <.input field={@ash_form[:description]} label="Description" />
        <.input type="json" field={@ash_form[:json_schema]} label="Schema" />
        <.input type="select" options={@status_options} field={@ash_form[:status]} label="Status" />
        <.input field={@ash_form[:type]} label="Type" />

        <h3 class="mb-4 text-lg font-bold text-gray-900 dark:text-white">Variables</h3>
        <.inputs_for :let={var_form} field={@ash_form[:variables]}>
          <div class="space-y-4 md:flex md:space-y-0 md:space-x-4">
            <div class="w-full">
              <.input field={var_form[:name]} label="Name" />
            </div>
            <div class="w-full">
              <.input field={var_form[:value]} label="Value" />
            </div>
            <div class="pt-7">
              <.button
                type="button"
                class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-xs dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
                phx-click="remove-variable"
                phx-value-path={var_form.name}
              >
                Remove
              </.button>
            </div>
          </div>
        </.inputs_for>

        <:actions>
          <.button type="button" phx-click="add-variable" phx-value-path={@ash_form[:variables].name}>
            <span :if={Enum.any?(AshPhoenix.Form.value(@ash_form, :variables))}>Add Additional Variable</span>
            <span :if={Enum.empty?(AshPhoenix.Form.value(@ash_form, :variables))}>Add Variable</span>
          </.button>

          <.button :if={@live_action == :edit}>Save</.button>
          <.button :if={@live_action == :new}>Create</.button>
          <.button :if={false} type="delete">Delete</.button>
        </:actions>
      </.simple_form>
      <div>
        <h3 class="mb-4 font-bold text-gray-900 dark:text-white">Example form:</h3>
        <div class="p-4">
          <.json_form
            form={@schema_form}
            json_schema={@json_schema}
            embed={true}
            add_custom_root={false}
            variables={HousingApp.Utils.MapUtil.array_to_map(AshPhoenix.Form.value(@ash_form, :variables))}
          />
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

  def mount(_params, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    ash_form =
      HousingApp.Management.Form
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Management,
        forms: [auto?: true],
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    ash_form = AshPhoenix.Form.validate(ash_form, %{"json_schema" => "{}"})

    {:ok,
     assign(socket,
       ash_form: ash_form,
       schema_form: to_form(%{"schema" => %{}}, as: "schema"),
       json_schema: %{},
       status_options: status_options(),
       sidebar: :forms,
       page_title: "New Form"
     )}
  end

  def handle_event("add-variable", %{"path" => path}, socket) do
    ash_form = AshPhoenix.Form.add_form(socket.assigns.ash_form, path, params: %{name: "", value: ""})
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("remove-variable", %{"path" => path}, socket) do
    ash_form = AshPhoenix.Form.remove_form(socket.assigns.ash_form, path)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("validate", %{"_target" => ["form", "json_schema"], "form" => params}, socket) do
    # ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, json_schema: Jason.decode!(params["json_schema"]))}
  rescue
    Jason.DecodeError ->
      {:noreply, socket}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("submit", %{"form" => params}, %{assigns: %{live_action: action}} = socket) do
    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           if(action == :new, do: "Successfully created the form.", else: "Successfully updated the form.")
         )
         |> push_navigate(to: ~p"/forms")}

      {:error, ash_form} ->
        dbg(ash_form)
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
