defmodule HousingApp.Utils.Filters do
  @moduledoc false

  # alias HousingApp.Utils.Random.Token

  def match_resource(resource, id, common_query, actor: actor, tenant: tenant) do
    # .exists?() has a bug that queries wrong

    resource
    |> Ash.Query.for_read(:match_by_id, %{id: id}, actor: actor, tenant: tenant, authorize?: false)
    |> filter_to_fragments(common_query.filter)
  end

  def filter_resource(resource, read_action, nil, actor: actor, tenant: tenant) do
    Ash.Query.for_read(resource, read_action, %{}, actor: actor, tenant: tenant)
  end

  # TODO: Should only do filter_to_fragments for profile data field
  # HousingApp.Utils.Filters.filter_resource(HousingApp.Assignments.Room, :list, %{filter: %{"and" => %{"data" => %{"programmatic" => %{"quiet" => true}}}}}, actor: nil, tenant: nil)
  def filter_resource(resource, read_action, %{filter: %{"and" => %{"data" => _data}}} = common_query,
        actor: actor,
        tenant: tenant
      ) do
    resource
    |> Ash.Query.for_read(read_action, %{}, actor: actor, tenant: tenant)
    |> filter_to_fragments(common_query.filter)
  end

  def filter_resource(resource, read_action, common_query, actor: actor, tenant: tenant) do
    {_combinator, statement} =
      case common_query.filter do
        %{"" => predicates} -> {"and", predicates}
        %{"and" => predicates} -> {"and", predicates}
        %{"or" => predicates} -> {"or", [or: predicates]}
      end

    # TODO: I think "or" is handled wrong, might need an array of arrays, see: https://hexdocs.pm/ash/2.17.17/Ash.Filter.html#module-keyword-list-syntax
    {:ok, filter} = Ash.Filter.parse_input(resource, statement)

    resource
    |> Ash.Query.for_read(read_action, %{}, actor: actor, tenant: tenant)
    |> Ash.Query.filter_input(filter)
  end

  def filter_to_fragments(query, %{"and" => %{"data" => predicate_map}}) do
    frags =
      Enum.flat_map(predicate_map, fn {k, v} ->
        create_fragment(k, v)
      end)

    Ash.Query.do_filter(query, frags)
  end

  # %{"and" => %{"data" => %{"programmatic" => %{"quiet" => true}}}}

  # #Ash.Query<
  #   resource: HousingApp.Assignments.Room,
  #   filter: #Ash.Filter<fragment(
  #     {:raw, ""},
  #     {:casted_expr, "data"},
  #     {:raw, "->"},
  #     {:casted_expr, "programmatic"},
  #     {:raw, "->>"},
  #     {:casted_expr, "quiet"},
  #     {:raw, " = "},
  #     {:casted_expr, true},
  #     {:raw, ""}
  #   )>
  # >

  defp create_fragment(field, value, path \\ [])

  defp create_fragment(field, value, path) when is_map(value) do
    Enum.flat_map(value, fn {k, v} ->
      create_fragment(k, v, path ++ [field])
    end)
  end

  defp create_fragment(field, value, []) do
    {:ok, frag} = AshPostgres.Functions.Fragment.casted_new(["data->>? = ?", field, value])
    [frag]
  end

  defp create_fragment(field, value, path) do
    query = Enum.map_join(path, "->", fn _ -> "?" end)
    query = Enum.join([query, "?"], "->>")
    {:ok, frag} = AshPostgres.Functions.Fragment.casted_new(["data->#{query} = ?"] ++ path ++ [field, value])
    [frag]
  end

  def ash_filter_to_react_query(%{} = filter) do
    # Convert from: %{"and" => %{"major" => "EE"}}
    {combinator, predicates} =
      case filter do
        %{"" => predicates} -> {"and", predicates}
        %{"and" => predicates} -> {"and", predicates}
        %{"or" => predicates} -> {"or", predicates}
      end

    rules =
      Enum.flat_map(predicates, fn {k, v} ->
        predicate_to_query(k, v)
      end)

    # FUTURE: , id: Token.generate()
    %{combinator: combinator, rules: rules}
  end

  defp predicate_to_query(field, %{} = value) do
    Enum.flat_map(value, fn {k, v} ->
      predicate_to_query("#{field}.#{k}", v)
    end)
  end

  defp predicate_to_query(field, value) do
    # FUTURE: , id: Token.generate()
    [%{field: field, operator: "=", value: value}]
  end

  def react_query_to_ash_filter("profile", query) do
    predicates =
      query
      |> Map.get("rules")
      |> Enum.reduce(%{}, fn rule, acc ->
        case rule["operator"] do
          "=" -> Map.put(acc, rule["field"], parse_value(rule["value"]))
          _ -> acc
        end
      end)

    Map.put(%{}, query["combinator"], predicates)
  end

  def react_query_to_ash_filter(_resource, query) do
    predicates =
      query
      |> Map.get("rules")
      |> Enum.reduce(%{}, fn rule, acc ->
        case rule["operator"] do
          "=" -> convert_filter(acc, String.split(rule["field"], "."), parse_value(rule["value"]))
          _ -> acc
        end
      end)

    Map.put(%{}, query["combinator"], predicates)
  end

  defp parse_value(val) when is_integer(val), do: val

  defp parse_value(val) do
    case Integer.parse(val) do
      {num, ""} -> num
      {_, _rest} -> val
      :error -> val
    end
  end

  defp convert_filter(map, [field | []], value) do
    Map.put(map, field, value)
  end

  defp convert_filter(map, [field | remaining], value) do
    HousingApp.Utils.MapUtil.deep_merge(map, %{field => convert_filter(%{}, remaining, value)})
  end
end
