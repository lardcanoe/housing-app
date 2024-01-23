defmodule HousingAppWeb.Live.Applications.Edit do
  @moduledoc false
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update application</h2>
      <.input field={@ash_form[:name]} label="Name" />
      <.input field={@ash_form[:description]} label="Description" />
      <.input type="select" options={@forms} field={@ash_form[:form_id]} label="Form" prompt="Select a form..." />
      <.input type="select" options={@time_periods} field={@ash_form[:time_period_id]} label="Time Period" />
      <.input type="select" options={@status_options} field={@ash_form[:status]} label="Status" />
      <.input field={@ash_form[:type]} label="Type" />
      <.input type="select" options={@submission_types} field={@ash_form[:submission_type]} label="Submission Type" />
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

      <:actions>
        <.button
          :if={Enum.any?(@common_query_options)}
          type="button"
          phx-click="add-condition"
          phx-value-path={@ash_form[:conditions].name}
        >
          <span :if={@ash_form[:conditions].value |> Enum.any?()}>Add Additional Condition</span>
          <span :if={@ash_form[:conditions].value |> Enum.empty?()}>Add Profile Eligibility Condition</span>
        </.button>
        <.button>Save</.button>
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
