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

  def to_html_form_inputs(schema) do
    required = MapSet.new(schema["required"] || [])

    schema["properties"]
    |> Enum.sort_by(fn {_, prop} -> prop["propertyOrder"] || 1000 end)
    |> Enum.map(fn {key, value} ->
      prop = to_html_input(key, value)

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

  defp to_html_input(key, value) do
    # IO.inspect(value, label: key)

    title =
      HousingApp.Utils.String.titlize(value["title"]) || value["description"] || HousingApp.Utils.String.titlize(key)

    case Map.get(value, "type") do
      "string" ->
        if value["enum"] do
          %{
            type: "select",
            name: key,
            id: key,
            label: title,
            options: value["enum"] |> Enum.map(fn v -> {v, v} end)
          }
        else
          %{
            type: value["format"] || "text",
            name: key,
            id: key,
            label: title,
            minlength: value["minLength"],
            maxlength: value["maxLength"]
          }
        end

      "integer" ->
        %{type: "number", name: key, id: key, label: title, min: value["minimum"], max: value["maximum"]}

      "boolean" ->
        %{type: "checkbox", name: key, id: key, label: title}

      "object" ->
        %{type: "object", title: title, definitions: to_html_form_inputs(value)}

      _ ->
        nil
    end
  end

  def extract_properties(schema) do
    schema["properties"]
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      case Map.get(value, "type") do
        type when type == "string" or type == "integer" or type == "boolean" ->
          Map.put(acc, String.to_atom(key), String.to_atom(type))

        _ ->
          acc
      end
    end)
  end

  def cast_params(schema, params) do
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

    changeset =
      {%{}, types}
      |> Ecto.Changeset.cast(params, Map.keys(types))

    changeset.changes
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, Atom.to_string(key), value)
    end)
  end

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
      |> IO.inspect()

    data = %{}

    required =
      (schema["required"] || [])
      |> Enum.map(&String.to_atom/1)
      |> Enum.reject(fn key -> !Map.has_key?(types, key) end)

    # types = %{name: :string, email: :string, age: :integer}
    params = %{name: "Callum", email: "callum@example.com", age: "27"}
    param_strings = params |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, to_string(key), value) end)

    ExJsonSchema.Validator.validate(schema, param_strings) |> IO.inspect()

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
