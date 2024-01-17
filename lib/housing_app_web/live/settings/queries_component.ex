defmodule HousingAppWeb.Components.Settings.Queries do
  @moduledoc false

  use HousingAppWeb, :live_component

  import HousingAppWeb.CoreComponents

  attr :current_user_tenant, :any, required: true
  attr :current_tenant, :string, required: true

  def render(%{query_form: nil} = assigns) do
    ~H"""
    <div class="hidden"></div>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <.table
        :if={@queries != []}
        id="queries-table"
        rows={@queries}
        pagination={false}
        row_id={fn row -> "query-row-#{row.id}" end}
      >
        <:col :let={q} label="name">
          <%= q.name %>
        </:col>
        <:col :let={q} label="description">
          <%= q.description %>
        </:col>
        <:col :let={q} label="resource">
          <%= q.resource %>
        </:col>
        <:col :let={q} label="edit">
          <.button phx-click="edit" phx-value-id={q.id} phx-target={@myself} type="button">
            Edit
          </.button>
        </:col>
      </.table>

      <.simple_form
        autowidth={false}
        class="mt-4"
        for={@query_form}
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
      >
        <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">
          <span :if={@query_form.source.action == :update}>Update Query</span>
          <span :if={@query_form.source.action == :create}>New Query</span>
        </h2>
        <.input field={@query_form[:name]} label="Name" />
        <.input field={@query_form[:description]} label="Description" />
        <.input
          type="select"
          options={@resource_types}
          field={@query_form[:resource]}
          label="Resource"
          {if(@query_form.source.action == :update, do: [{"disabled", ""}], else: [])}
        />

        <div id="query-builder" name="cq_form[filters]" class="mb-4" phx-hook="QueryBuilder" phx-update="ignore" />

        <:actions>
          <.button>
            <span :if={@query_form.source.action == :update}>Update</span>
            <span :if={@query_form.source.action == :create}>Add</span>
          </.button>
        </:actions>
      </.simple_form>

      <.simple_form
        :let={filter_form}
        :if={false && @filter_form}
        id="filter-form"
        for={@filter_form}
        phx-change="filter_validate"
        phx-submit="filter_submit"
        phx-target={@myself}
        autowidth={false}
      >
        <.filter_form_component component={filter_form} myself={@myself} />
        <:actions>
          <.button>Submit</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  attr :component, :map, required: true
  attr :root_group, :boolean, default: true
  attr :myself, :any, required: true

  defp filter_form_component(%{component: %{source: %AshPhoenix.FilterForm{}}} = assigns) do
    ~H"""
    <div class="border-gray-50 border-8 p-4 rounded-xl mt-4">
      <div class="flex flex-row justify-between">
        <div class="flex flex-row gap-2 items-center">
          <%= if @root_group, do: "Filter", else: "Group" %>
          <.input type="select" field={@component[:operator]} options={[And: "and", Or: "or"]} />
        </div>
        <div>
          <.button
            phx-click="add_filter_group"
            phx-value-component-id={@component.source.id}
            phx-target={@myself}
            type="button"
          >
            Add Group
          </.button>
          <.button
            phx-click="add_filter_predicate"
            phx-value-component-id={@component.source.id}
            phx-target={@myself}
            type="button"
          >
            Add Predicate
          </.button>
          <%= if @root_group do %>
            <.button phx-click="clear_filter" phx-target={@myself} type="button">
              Clear Filter
            </.button>
            <.button phx-click="remove_filter" phx-target={@myself} type="button">
              Remove Filter
            </.button>
          <% else %>
            <.button
              phx-click="remove_filter_component"
              phx-value-component-id={@component.source.id}
              phx-target={@myself}
              type="button"
            >
              Remove Group
            </.button>
          <% end %>
        </div>
      </div>
      <.inputs_for :let={component} field={@component[:components]}>
        <.filter_form_component component={component} root_group={false} myself={@myself} />
      </.inputs_for>
    </div>
    """
  end

  defp filter_form_component(%{component: %{source: %AshPhoenix.FilterForm.Predicate{}}} = assigns) do
    ~H"""
    <div class="flex flex-row gap-2 mt-4">
      <.input
        type="select"
        options={AshPhoenix.FilterForm.fields(HousingApp.Management.Profile)}
        field={@component[:field]}
      />
      <.input
        type="select"
        options={AshPhoenix.FilterForm.predicates(HousingApp.Management.Profile)}
        field={@component[:operator]}
      />
      <.input field={@component[:value]} />
      <.button
        phx-click="remove_filter_component"
        phx-value-component-id={@component.source.id}
        phx-target={@myself}
        type="button"
      >
        Remove
      </.button>
    </div>
    """
  end

  def mount(socket) do
    {:ok,
     assign(socket, query_form: nil, queries: [], resource_types: resource_options(), filter_form: build_filter_form())}
  end

  def update(params, socket) do
    {:ok,
     socket
     |> assign(params)
     |> load_resource_fields("profile")
     |> reset_query_fields()}
  end

  defp load_resource_fields(socket, "profile") do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Management.Service.get_profile_form(actor: current_user_tenant, tenant: tenant) do
      {:ok, profile_form} ->
        fields =
          profile_form.json_schema
          |> Jason.decode!()
          |> Map.get("properties")
          |> Enum.map(fn {k, v} ->
            %{name: k, label: v["title"] || String.capitalize(k)}
          end)

        assign(socket, resource_fields: fields)

      _ ->
        socket
    end
  end

  defp load_resource_fields(socket, "booking") do
    fields =
      resource_fields(HousingApp.Assignments.Booking)

    assign(socket, resource_fields: fields)
  end

  defp resource_fields(resource, path \\ []) do
    resource_fields =
      resource
      |> Ash.Resource.Info.public_aggregates()
      |> Enum.concat(Ash.Resource.Info.public_calculations(resource))
      |> Enum.concat(Ash.Resource.Info.public_attributes(resource))
      |> Enum.map(&%{name: Enum.join(path ++ [&1.name], "."), label: Enum.join(path ++ [&1.name], " / ")})

    relations =
      resource
      |> Ash.Resource.Info.public_relationships()
      |> Enum.filter(&(&1.type == :belongs_to && &1.name != :tenant && &1.name != :user_tenant))
      |> Enum.flat_map(&resource_fields(&1.destination, path ++ [&1.name]))

    # IO.inspect(resource)
    # IO.inspect(Enum.concat(relations, resource_fields))
    # IO.puts("--------")

    Enum.concat(relations, resource_fields)
  end

  defp reset_query_fields(socket) do
    %{resource_fields: resource_fields, current_user_tenant: current_user_tenant, current_tenant: tenant} =
      socket.assigns

    first_field = hd(resource_fields)

    socket
    |> assign(
      queries: load_queries(current_user_tenant, tenant),
      query_form:
        management_form_for_create(HousingApp.Management.CommonQuery, :create,
          as: "cq_form",
          actor: current_user_tenant,
          tenant: tenant
        ),
      query: %{combinator: "", rules: [%{field: first_field[:name], operator: "=", value: ""}]}
    )
    |> load_resource_fields("profile")
  end

  def handle_event("load-query", _params, socket) do
    %{query: query, resource_fields: resource_fields} = socket.assigns
    {:reply, %{query: query, fields: resource_fields}, socket}
  end

  def handle_event("query-changed", %{"q" => q}, socket) do
    {:noreply, assign(socket, query: q)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    %{queries: queries, current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case Enum.find(queries, &(&1.id == id)) do
      nil ->
        {:noreply, socket}

      cq ->
        query = HousingApp.Utils.Filters.ash_filter_to_react_query(cq.filter)

        {:noreply,
         socket
         |> assign(
           query_form:
             management_form_for_update(cq, :update, as: "cq_form", actor: current_user_tenant, tenant: tenant),
           query: query
         )
         |> load_resource_fields(Atom.to_string(cq.resource))
         |> push_event("query-builder:refresh", %{})}
    end
  end

  def handle_event("validate", %{"_target" => ["cq_form", "resource"], "cq_form" => params}, socket) do
    query_form = AshPhoenix.Form.validate(socket.assigns.query_form, params)
    {:noreply, socket |> assign(query_form: query_form) |> load_resource_fields(params["resource"])}
  end

  def handle_event("validate", _data, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"cq_form" => data}, socket) do
    %{query_form: query_form, query: query} = socket.assigns

    ash_filter = HousingApp.Utils.Filters.react_query_to_ash_filter(data["resource"], query)
    data = Map.put(data, "filter", ash_filter)

    case AshPhoenix.Form.submit(query_form, params: data) do
      {:ok, _cq} ->
        {:noreply, socket |> reset_query_fields() |> push_event("query-builder:refresh", %{})}

      {:error, query_form} ->
        dbg(query_form)
        {:noreply, assign(socket, query_form: query_form)}
    end
  end

  def handle_event("filter_validate", %{"filter" => params}, socket) do
    {:noreply,
     assign(socket,
       filter_form: AshPhoenix.FilterForm.validate(socket.assigns.filter_form, params)
     )}
  end

  def handle_event("filter_submit", %{"filter" => params}, socket) do
    filter_form = AshPhoenix.FilterForm.validate(socket.assigns.filter_form, params)
    filter = AshPhoenix.FilterForm.filter(Employee, filter_form)

    case filter do
      {:ok, _query} ->
        {:noreply, assign(socket, :filter_form, filter_form)}

      {:error, filter_form} ->
        {:noreply, assign(socket, filter_form: filter_form)}
    end
  end

  def handle_event("remove_filter_component", %{"component-id" => component_id}, socket) do
    {:noreply,
     assign(socket,
       filter_form: AshPhoenix.FilterForm.remove_component(socket.assigns.filter_form, component_id)
     )}
  end

  def handle_event("add_filter_group", %{"component-id" => component_id}, socket) do
    {:noreply,
     assign(socket,
       filter_form: AshPhoenix.FilterForm.add_group(socket.assigns.filter_form, to: component_id)
     )}
  end

  def handle_event("add_filter_predicate", %{"component-id" => component_id}, socket) do
    {:noreply,
     assign(socket,
       filter_form:
         AshPhoenix.FilterForm.add_predicate(socket.assigns.filter_form, :name, :contains, nil, to: component_id)
     )}
  end

  def handle_event("add_filter", _, socket) do
    {:noreply, assign(socket, filter_form: build_filter_form())}
  end

  def handle_event("remove_filter", _, socket) do
    {:noreply, assign(socket, filter_form: nil)}
  end

  def handle_event("clear_filter", _, socket) do
    {:noreply, assign(socket, filter_form: build_filter_form())}
  end

  defp build_filter_form do
    AshPhoenix.FilterForm.new(HousingApp.Management.Profile)
    # |> AshPhoenix.FilterForm.add_predicate(:name, :contains, nil)
  end

  defp load_queries(current_user_tenant, tenant) do
    HousingApp.Management.CommonQuery.list!(actor: current_user_tenant, tenant: tenant)
  end
end
