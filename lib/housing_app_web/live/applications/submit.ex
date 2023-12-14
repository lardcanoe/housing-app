defmodule HousingAppWeb.Live.Applications.Submit do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :submit} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit" autocomplete="off">
      <h1
        :if={!is_nil(@json_schema["title"]) && @json_schema["title"] != ""}
        class="mb-4 text-xl font-bold text-gray-900 dark:text-white"
      >
        <%= @json_schema["title"] %>
      </h1>

      <%= render_schema(%{definitions: @definitions, ash_form: @ash_form}) %>

      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  defp render_schema(assigns) do
    ~H"""
    <%= for definition <- @definitions do %>
      <%= case definition.type do %>
        <% "object" -> %>
          <h3
            :if={!is_nil(definition.title) && definition.title != ""}
            class="mb-4 text-xl font-bold text-gray-900 dark:text-white"
          >
            <%= definition.title %>
          </h3>
          <%= render_schema(%{definitions: definition.definitions, ash_form: @ash_form}) %>
        <% _ -> %>
          <.input field={@ash_form[String.to_atom(definition.name)]} data-lpignore="true" {definition} />
      <% end %>
    <% end %>
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
           json_schema: json_schema,
           definitions: HousingApp.Utils.JsonSchema.to_html_form_inputs(json_schema),
           ash_form: %{} |> to_form(),
           sidebar: :applications,
           page_title: "Submit Application"
         )}
    end
  end

  def handle_event("load-schema", _params, socket) do
    {:reply, %{schema: socket.assigns.json_schema}, socket}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", data, socket) do
    data = HousingApp.Utils.JsonSchema.cast_params(socket.assigns.json_schema, data) |> IO.inspect()

    ref_schema = ExJsonSchema.Schema.resolve(socket.assigns.json_schema)

    case ExJsonSchema.Validator.validate(ref_schema, data) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Thank you for your submission!")
         |> push_navigate(to: ~p"/applications")}

      {:error, errors} ->
        IO.inspect(errors)

        {:noreply,
         socket
         |> assign(ash_form: data |> to_form() |> IO.inspect())
         |> put_flash(:error, "Errors present in form submission.")}
    end
  end
end
