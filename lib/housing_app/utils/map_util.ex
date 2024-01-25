defmodule HousingApp.Utils.MapUtil do
  @moduledoc """
  https://stackoverflow.com/questions/38864001/elixir-how-to-deep-merge-maps/38865647#38865647
  """

  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, %{} = left, %{} = right) do
    deep_merge(left, right)
  end

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right) do
    right
  end

  def keys_to_atoms(json) when is_map(json) do
    Map.new(json, &reduce_keys_to_atoms/1)
  end

  def keys_to_strings(json) when is_map(json) do
    Map.new(json, &reduce_keys_to_strings/1)
  end

  def array_to_map(nil), do: %{}

  def array_to_map(variables) when is_list(variables) do
    Enum.reduce(variables, %{}, fn %{name: key, value: value}, acc ->
      Map.put(acc, key, value)
    end)
  end

  def array_to_map(variables) when is_map(variables) do
    Enum.reduce(variables, %{}, fn {_index, variable}, acc ->
      case variable do
        %{"name" => key, "value" => value} ->
          Map.put(acc, key, value)

        _ ->
          acc
      end
    end)
  end

  defp reduce_keys_to_atoms({key, val}) when is_map(val), do: {String.to_atom(key), keys_to_atoms(val)}

  defp reduce_keys_to_atoms({key, val}) when is_list(val), do: {String.to_atom(key), Enum.map(val, &keys_to_atoms(&1))}

  defp reduce_keys_to_atoms({key, val}), do: {String.to_atom(key), val}

  defp reduce_keys_to_strings({key, val}) when is_map(val), do: {Atom.to_string(key), keys_to_strings(val)}

  defp reduce_keys_to_strings({key, val}) when is_list(val),
    do: {Atom.to_string(key), Enum.map(val, &keys_to_strings(&1))}

  defp reduce_keys_to_strings({key, val}), do: {Atom.to_string(key), val}
end
