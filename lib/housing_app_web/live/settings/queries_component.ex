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
      </.table>

      <.simple_form
        autowidth={false}
        class="mt-4"
        for={@query_form}
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
      >
        <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Query</h2>
        <.input field={@query_form[:name]} label="Name" />
        <.input field={@query_form[:description]} label="Description" />
        <.input type="select" options={@resource_types} field={@query_form[:resource]} label="Resource" />

        <div
          id="query-builder"
          name="cq_form[filters]"
          class="mb-4"
          phx-hook="QueryBuilder"
          phx-update="ignore"
          data-query={@query}
          data-fields={@fields}
        />

        <:actions>
          <.button>Add</.button>
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
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = params

    case HousingApp.Management.Service.get_profile_form(actor: current_user_tenant, tenant: tenant) do
      {:ok, profile_form} ->
        fields =
          profile_form.json_schema
          |> Jason.decode!()
          |> Map.get("properties")
          |> Enum.map(fn {k, v} ->
            %{name: k, label: v["title"] || String.capitalize(k)}
          end)

        {:ok,
         socket
         |> assign(params)
         |> assign(resource_fields: fields)
         |> assign(fields: Jason.encode!(fields))
         |> reset_query_fields()}

      _ ->
        assign(socket, params)
    end
  end

  defp reset_query_fields(socket) do
    %{resource_fields: resource_fields, current_user_tenant: current_user_tenant, current_tenant: tenant} =
      socket.assigns

    first_field = hd(resource_fields)

    assign(socket,
      queries: load_queries(current_user_tenant, tenant),
      query_form:
        HousingApp.Management.CommonQuery
        |> generate_management_ash_form(:create, "cq_form",
          actor: current_user_tenant,
          tenant: tenant
        )
        |> dbg(),
      query: Jason.encode!(%{combinator: "", rules: [%{field: first_field[:name], operator: "=", value: ""}]})
    )
  end

  def handle_event("query-changed", %{"q" => q}, socket) do
    {:noreply, assign(socket, query: Jason.encode!(q))}
  end

  def handle_event("validate", _data, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"cq_form" => data}, socket) do
    %{query_form: query_form} = socket.assigns

    data = Map.put(data, "filter", socket.assigns.query |> Jason.decode!() |> react_query_to_ash_filter())

    case AshPhoenix.Form.submit(query_form, params: data) do
      {:ok, _cq} ->
        {:noreply, reset_query_fields(socket)}

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

    # {:ok, frag1} = AshPostgres.Functions.Fragment.casted_new(["data->'location'->>'city' = ?", "Boston"])
    # HousingApp.Management.Profile |> Ash.Query.for_read(:read, %{}, actor: ut, tenant: "tenant_9d3b4eb3-f3d1-467f-abb5-51ddb6a71b18") |> Ash.Query.do_filter([frag1, frag2]) |> HousingApp.Management.exists?()

    # |> AshPhoenix.FilterForm.add_predicate(:name, :contains, nil)
  end

  defp load_queries(current_user_tenant, tenant) do
    HousingApp.Management.CommonQuery.list!(actor: current_user_tenant, tenant: tenant)
  end

  defp react_query_to_ash_filter(query, combinator \\ "and") do
    predicates =
      query
      |> Map.get("rules")
      |> Enum.reduce(%{}, fn rule, acc ->
        case rule["operator"] do
          "=" -> Map.put(acc, rule["field"], rule["value"])
          _ -> acc
        end
      end)

    Map.put(%{}, combinator, predicates)
  end
end
