defmodule HousingApp.Checks.SanitizeData do
  @moduledoc """
  Extracts the data from the record based on the actor's role
  https://hexdocs.pm/ash/calculations.html
  https://hexdocs.pm/ash/dsl-ash-resource.html#calculations

  Usage:

    calculations do
      calculate :sanitized_data, :map, HousingApp.Checks.SanitizeData
    end
  """

  use Ash.Calculation

  @impl true
  # A callback to tell Ash what keys must be loaded/selected when running this calculation
  def load(_query, _opts, _context) do
    [:sanitized_data]
  end

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn record ->
      record.sanitized_data
      # Map.put(record._data, "age", "***")
    end)
  end
end
