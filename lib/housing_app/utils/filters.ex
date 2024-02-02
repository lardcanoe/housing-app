defmodule HousingApp.Utils.Filters do
  @moduledoc false
  require Ash.Expr
  require Ash.Query

  # alias HousingApp.Utils.Random.Token

  def match_resource(resource, id, common_query, actor: actor, tenant: tenant) do
    # .exists?() has a bug that queries wrong

    resource
    |> Ash.Query.for_read(:match_by_id, %{id: id}, actor: actor, tenant: tenant, authorize?: false)
    |> parse_common_query(resource, common_query)
  end

  def filter_resource(resource, read_action, nil, actor: actor, tenant: tenant) do
    Ash.Query.for_read(resource, read_action, %{}, actor: actor, tenant: tenant)
  end

  def filter_resource(resource, read_action, common_query, actor: actor, tenant: tenant) do
    resource
    |> Ash.Query.for_read(read_action, %{}, actor: actor, tenant: tenant)
    |> parse_common_query(resource, common_query)
  end

  defp parse_common_query(query, resource, common_query) do
    {_combinator, statement} =
      case common_query.filter do
        %{"" => predicates} -> {"and", predicates}
        %{"and" => predicates} -> {"and", predicates}
        %{"or" => predicates} -> {"or", [or: predicates]}
      end

    statement = convert_data_filters_to_paths(statement)
    statement = adjust_path_of_filter(resource, common_query, statement)

    # Example:
    # statement = %{
    #   "room" => %{"building" => %{"name" => "Daniels", "data" => %{"at_path" => ["size"], "eq" => "King"}}},
    #   "data" => %{"at_path" => ["size"], "eq" => "King"}
    # }

    # FUTURE: Currently, due to Ash implementation of at_path, `data` can't be an array
    #         If someone has multiple "data" filters, then each needs to have its own `Ash.Query.filter_input` call

    # TODO: I think "or" is handled wrong, might need an array of arrays, see: https://hexdocs.pm/ash/2.17.17/Ash.Filter.html#module-keyword-list-syntax
    case Ash.Filter.parse_input(resource, statement) do
      {:ok, filter} ->
        Ash.Query.filter_input(query, filter)

      {:error, e} ->
        Ash.Query.add_error(query, e)
    end
  end

  defp convert_data_filters_to_paths(query) when is_map(query) do
    Enum.reduce(query, %{}, fn {k, v}, acc ->
      value =
        case k do
          "data" ->
            data_filter_to_path(v)

          _ ->
            # Need to traverse the entire depth, since we don't know how deep the data filters are
            convert_data_filters_to_paths(v)
        end

      Map.put(acc, k, value)
    end)
  end

  defp convert_data_filters_to_paths(query) do
    query
  end

  defp data_filter_to_path(value, path \\ [])

  defp data_filter_to_path(value, path) when is_map(value) do
    Enum.flat_map(value, fn {k, v} ->
      data_filter_to_path(v, path ++ [k])
    end)
  end

  defp data_filter_to_path(value, path) do
    %{at_path: path, eq: value}
  end

  defp adjust_path_of_filter(HousingApp.Assignments.Booking, %{resource: :profile}, statement) do
    statement =
      statement
      |> Map.put("sanitized_data", Map.get(statement, "data"))
      |> Map.delete("data")

    %{"profile" => statement}
  end

  defp adjust_path_of_filter(HousingApp.Assignments.Booking, %{resource: :bed}, statement) do
    %{"bed" => statement}
  end

  defp adjust_path_of_filter(HousingApp.Assignments.Booking, %{resource: :room}, statement) do
    %{"bed" => %{"room" => statement}}
  end

  defp adjust_path_of_filter(HousingApp.Assignments.Booking, %{resource: :building}, statement) do
    %{"bed" => %{"room" => %{"building" => statement}}}
  end

  defp adjust_path_of_filter(HousingApp.Assignments.Bed, %{resource: :room}, statement) do
    %{"room" => statement}
  end

  defp adjust_path_of_filter(HousingApp.Assignments.Bed, %{resource: :building}, statement) do
    %{"room" => %{"building" => statement}}
  end

  defp adjust_path_of_filter(HousingApp.Assignments.Room, %{resource: :building}, statement) do
    %{"building" => statement}
  end

  defp adjust_path_of_filter(HousingApp.Management.Profile, %{resource: :profile}, statement) do
    statement
    |> Map.put("sanitized_data", Map.get(statement, "data"))
    |> Map.delete("data")
  end

  defp adjust_path_of_filter(_resource, _common_query, statement) do
    statement
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

  def react_query_to_ash_filter(query) do
    predicates =
      query
      |> Map.get("rules")
      |> Enum.reduce(%{}, fn rule, acc ->
        case rule["operator"] do
          "=" -> convert_filter(acc, String.split(rule["field"], "."), parse_value(rule["value"]))
          _ -> acc
        end
      end)

    combinator =
      if not is_nil(query["combinator"]) && query["combinator"] != "" do
        query["combinator"]
      else
        "and"
      end

    Map.put(%{}, combinator, predicates)
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
