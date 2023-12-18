defmodule HousingAppWeb.Live.Applications.Submit do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :submit, current_user_tenant: %{user_type: :user}} = assigns) do
    ~H"""
    <.simple_form for={@form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white"><%= @application_name %></h2>

      <.json_form form={%{"data" => %{}} |> to_form(as: "data")} json_schema={@json_schema} embed={true} prefix="form" />

      <:actions>
        <.button>Submit</.button>
      </:actions>
    </.simple_form>
    """
  end

  def render(%{live_action: :submit} = assigns) do
    ~H"""
    <.simple_form for={@form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white"><%= @application_name %></h2>
      <.async_result :let={profiles} assign={@profiles}>
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

      <.json_form form={%{"data" => %{}} |> to_form(as: "data")} json_schema={@json_schema} embed={true} prefix="form" />

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
        json_schema = app.form.json_schema |> Jason.decode!()

        {:ok,
         assign(socket,
           application_id: app.id,
           application_name: app.name,
           json_schema: json_schema,
           form: %{"profile_id" => "", "data" => %{}} |> to_form(as: "form"),
           sidebar: :applications,
           page_title: "Submit Application"
         )
         |> load_async_assigns()}
    end
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
        %{assigns: %{application_id: application_id, current_user_tenant: current_user_tenant, current_tenant: tenant}} =
          socket
      ) do
    json_data = HousingApp.Utils.JsonSchema.cast_params(socket.assigns.json_schema, json_data)

    ref_schema = ExJsonSchema.Schema.resolve(socket.assigns.json_schema)

    actor =
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

    case ExJsonSchema.Validator.validate(ref_schema, json_data) do
      :ok ->
        case HousingApp.Management.ApplicationSubmission.submit(
               %{application_id: application_id, data: json_data},
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
end
