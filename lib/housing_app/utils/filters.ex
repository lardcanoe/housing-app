defmodule HousingApp.Utils.Filters do
  @moduledoc false

  # alias HousingApp.Utils.Random.Token

  def ash_filter_to_react_query(%{"and" => predicates}) do
    # Convert from: %{"and" => %{"major" => "EE"}}

    rules =
      Enum.flat_map(predicates, fn {k, v} ->
        predicate_to_query(k, v)
      end)

    # FUTURE: , id: Token.generate()
    %{combinator: "and", rules: rules}
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
