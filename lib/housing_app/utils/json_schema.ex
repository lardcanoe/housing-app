defmodule HousingApp.Utils.JsonSchema do
  @moduledoc false

  # https://www.ag-grid.com/javascript-data-grid/column-definitions/

  def schema_to_aggrid_columns(schema, prefix \\ "") do
    schema
    |> Map.get("properties")
    |> Enum.map(fn {key, value} ->
      case value do
        %{"type" => "integer"} ->
          %{field: "#{prefix}#{key}", type: "numericColumn", headerName: Map.get(value, "title", key)}

        %{"type" => "string", "format" => "date"} ->
          %{
            field: "#{prefix}#{key}",
            type: ["dateColumn", "nonEditableColumn"],
            width: 220,
            headerName: Map.get(value, "title", key)
          }

        %{"type" => "object"} ->
          %{
            field: "#{prefix}#{key}",
            groupId: "#{prefix}#{key}Group",
            headerName: Map.get(value, "title", key),
            children: schema_to_aggrid_columns(value, "#{prefix}#{key}.")
          }

        _ ->
          %{field: "#{prefix}#{key}", headerName: Map.get(value, "title", key)}
      end
    end)
  end
end
