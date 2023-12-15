defmodule HousingApp.Utils.JsonSchema do
  @moduledoc false

  # https://www.ag-grid.com/javascript-data-grid/column-definitions/

  def schema_to_aggrid_columns(scheman, prefix \\ "")

  def schema_to_aggrid_columns(%{"properties" => properties}, prefix) when not is_nil(properties) do
    properties
    |> Enum.map(fn {key, value} ->
      headerName = HousingApp.Utils.String.titlize(key)

      case value do
        %{"type" => "integer"} ->
          %{
            field: "#{prefix}#{key}",
            type: "numericColumn",
            headerName: headerName,
            headerTooltip: Map.get(value, "title")
          }

        %{"type" => "boolean"} ->
          %{
            field: "#{prefix}#{key}",
            cellRenderer: "booleanCheckmark",
            headerName: headerName,
            headerTooltip: Map.get(value, "title")
          }

        %{"type" => "string", "format" => "date"} ->
          %{
            field: "#{prefix}#{key}",
            type: ["dateColumn", "nonEditableColumn"],
            width: 220,
            headerName: headerName,
            headerTooltip: Map.get(value, "title")
          }

        %{"type" => "object"} ->
          %{
            field: "#{prefix}#{key}",
            groupId: "#{prefix}#{key}Group",
            headerName: headerName,
            children: schema_to_aggrid_columns(value, "#{prefix}#{key}."),
            headerTooltip: Map.get(value, "title")
          }

        _ ->
          %{field: "#{prefix}#{key}", headerName: headerName, headerTooltip: Map.get(value, "title")}
      end
    end)
  end

  def schema_to_aggrid_columns(%{}, _prefix), do: []

  def to_html_form_inputs(schema, name_prefix \\ "")

  def to_html_form_inputs(%{"properties" => properties} = schema, name_prefix) when not is_nil(properties) do
    required = MapSet.new(schema["required"] || [])

    properties
    |> Enum.sort_by(fn {_, prop} -> prop["propertyOrder"] || 1000 end)
    |> Enum.map(fn {key, value} ->
      prop = to_html_input(key, value, name_prefix)

      if is_nil(prop) do
        nil
      else
        if MapSet.member?(required, key) do
          Map.put(prop, :required, "")
        else
          prop
        end
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def to_html_form_inputs(%{}, _name_prefix), do: []

  defp to_html_input(key, value, name_prefix) do
    title =
      HousingApp.Utils.String.titlize(value["title"]) || value["description"] || HousingApp.Utils.String.titlize(key)

    name =
      if name_prefix == "" do
        key
      else
        "#{name_prefix}[#{key}]"
      end

    id_prefix =
      if name_prefix == "" do
        ""
      else
        (name_prefix |> String.replace(["[", "]"], "")) <> "-"
      end

    id = String.replace("#{id_prefix}#{key}", ".", "-") <> "-field"

    key = String.to_atom(key)

    case value do
      %{"type" => "string", "template" => template} when is_binary(template) and template != "" ->
        nil

      %{"type" => "string", "enum" => enum} when is_list(enum) ->
        %{
          type: "select",
          key: key,
          name: name,
          id: id,
          label: title,
          options: enum |> Enum.map(fn v -> {v, v} end)
        }

      %{"type" => "string"} ->
        %{
          type: value["format"] || "text",
          key: key,
          name: name,
          id: id,
          label: title,
          minlength: value["minLength"],
          maxlength: value["maxLength"]
        }

      %{"type" => "integer"} ->
        %{type: "number", key: key, name: name, id: id, label: title, min: value["minimum"], max: value["maximum"]}

      %{"type" => "boolean"} ->
        %{type: "checkbox", key: key, name: name, id: id, label: title}

      %{"type" => "object"} ->
        %{type: "object", key: key, id: id, title: title, definitions: to_html_form_inputs(value, name)}

      _ ->
        nil
    end
  end

  def extract_properties(%{"properties" => properties}) when is_map(properties) do
    properties
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      case value do
        %{"template" => template} when is_binary(template) and template != "" ->
          acc

        %{"type" => type} when type == "string" or type == "integer" or type == "boolean" ->
          Map.put(acc, String.to_atom(key), String.to_atom(type))

        _ ->
          acc
      end
    end)
  end

  def extract_properties(%{}), do: []

  def cast_params(%{"properties" => properties} = schema, params) when is_map(properties) do
    types = extract_properties(schema)

    changeset =
      {%{}, types}
      |> Ecto.Changeset.cast(params, Map.keys(types))

    converted =
      changeset.changes
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        Map.put(acc, Atom.to_string(key), value)
      end)

    nested =
      properties
      |> Enum.map(fn {key, value} ->
        case Map.get(value, "type") do
          "object" ->
            {key, cast_params(value, params[key])}

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Map.new()

    Map.merge(converted, nested)
  end

  def cast_params(%{}, _params), do: %{}

  def validate_against_schema() do
    schema =
      """
      {
        "title": "Profile",
        "type": "object",
        "required": [
          "name",
          "age",
          "date",
          "favorite_color",
          "gender",
          "location",
          "pets"
        ],
        "properties": {
          "name": {
            "type": "string",
            "description": "First and Last name",
            "minLength": 3,
            "default": "Jeremy Dorn"
          },
          "email": {
            "type": "string",
            "format": "email"
          },
          "happy": {
            "type": "boolean",
            "default": false
          },
          "age": {
            "type": "integer",
            "default": 25,
            "minimum": 18,
            "maximum": 99
          },
          "favorite_color": {
            "type": "string",
            "format": "color",
            "title": "favorite color",
            "default": "#ffa500"
          },
          "gender": {
            "type": "string",
            "enum": [
              "male",
              "female",
              "other"
            ]
          },
          "date": {
            "type": "string",
            "format": "date",
            "options": {
              "flatpickr": {}
            }
          },

          "location": {
            "type": "object",
            "title": "Location",
            "properties": {
              "city": {
                "type": "string",
                "default": "San Francisco"
              },
              "state": {
                "type": "string",
                "default": "CA"
              },
              "citystate": {
                "type": "string",
                "description": "This is generated automatically from the previous two fields",
                "template": "{{city}}, {{state}}",
                "watch": {
                  "city": "location.city",
                  "state": "location.state"
                }
              }
            },
            "required": [
          "city"
        ]
          },
          "pets": {
            "type": "array",
            "format": "table",
            "title": "Pets",
            "uniqueItems": true,
            "items": {
              "type": "object",
              "title": "Pet",
              "properties": {
                "type": {
                  "type": "string",
                  "enum": [
                    "cat",
                    "dog",
                    "bird",
                    "reptile",
                    "other"
                  ],
                  "default": "dog"
                },
                "name": {
                  "type": "string"
                }
              }
            },
            "default": [
              {
                "type": "dog",
                "name": "Walter"
              }
            ]
          }
        }
      }
      """
      |> Jason.decode!()

    types =
      schema["properties"]
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        case Map.get(value, "type") do
          type when type == "string" or type == "integer" or type == "boolean" ->
            Map.put(acc, String.to_atom(key), String.to_atom(type))

          _ ->
            acc
        end
      end)

    data = %{}

    required =
      (schema["required"] || [])
      |> Enum.map(&String.to_atom/1)
      |> Enum.reject(fn key -> !Map.has_key?(types, key) end)

    # types = %{name: :string, email: :string, age: :integer}
    params = %{name: "Callum", email: "callum@example.com", age: "27"}
    param_strings = params |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, to_string(key), value) end)

    ExJsonSchema.Validator.validate(schema, param_strings)

    {data, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required(required)

    # |> Ecto.Changeset.validate_length(...)

    # case Jason.decode(data) do
    #   {:ok, data} ->
    #     case Jason.decode(schema) do
    #       {:ok, schema} ->
    #         case JasonSchema.validate(schema, data) do
    #           {:ok, _} ->
    #             {:ok, data}

    #           {:error, errors} ->
    #             {:error, errors}
    #         end

    #       {:error, _} ->
    #         {:error, "Invalid schema"}
    #     end

    #   {:error, _} ->
    #     {:error, "Invalid data"}
    # end
  end
end
