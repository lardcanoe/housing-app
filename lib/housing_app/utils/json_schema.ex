defmodule HousingApp.Utils.JsonSchema do
  @moduledoc false

  # https://www.ag-grid.com/javascript-data-grid/column-definitions/

  def schema_to_aggrid_columns(scheman, prefix \\ "")

  def schema_to_aggrid_columns(%{"properties" => properties}, prefix) when not is_nil(properties) do
    Enum.map(properties, fn {key, value} ->
      header_name = HousingApp.Utils.String.titlize(key)

      case value do
        %{"type" => "integer"} ->
          %{
            field: "#{prefix}#{key}",
            type: "numericColumn",
            headerName: header_name,
            headerTooltip: Map.get(value, "title")
          }

        %{"type" => "boolean"} ->
          %{
            field: "#{prefix}#{key}",
            cellRenderer: "booleanCheckmark",
            headerName: header_name,
            headerTooltip: Map.get(value, "title")
          }

        %{"type" => "string", "format" => "date"} ->
          %{
            field: "#{prefix}#{key}",
            type: ["dateColumn", "nonEditableColumn"],
            width: 220,
            headerName: header_name,
            headerTooltip: Map.get(value, "title")
          }

        %{"type" => "array", "items" => %{"enum" => enum}} when is_list(enum) ->
          %{
            field: "#{prefix}#{key}",
            # FUTURE: Maybe a special tag cell
            width: 220,
            headerName: header_name,
            headerTooltip: Map.get(value, "title")
          }

        %{"type" => "object"} ->
          %{
            field: "#{prefix}#{key}",
            groupId: "#{prefix}#{key}Group",
            headerName: header_name,
            children: schema_to_aggrid_columns(value, "#{prefix}#{key}."),
            headerTooltip: Map.get(value, "title")
          }

        _ ->
          %{field: "#{prefix}#{key}", headerName: header_name, headerTooltip: Map.get(value, "title")}
      end
    end)
  end

  def schema_to_aggrid_columns(%{}, _prefix), do: []

  def to_html_form_inputs(schema, name_prefix \\ "", opts \\ [])

  def to_html_form_inputs(%{"properties" => properties} = schema, name_prefix, opts) when not is_nil(properties) do
    required = MapSet.new(schema["required"] || [])

    properties
    |> Enum.sort_by(fn {_, prop} -> prop["propertyOrder"] || 1000 end)
    |> Enum.map(fn {key, value} ->
      prop = to_html_input(key, value, name_prefix, opts)

      cond do
        is_nil(prop) -> nil
        MapSet.member?(required, key) -> Map.put(prop, :required, "")
        true -> prop
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def to_html_form_inputs(%{}, _name_prefix, _opts), do: []

  defp to_html_input(key, value, name_prefix, opts) do
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
        String.replace(name_prefix, ["[", "]"], "") <> "-"
      end

    id = String.replace("#{id_prefix}#{key}", ".", "-") <> "-field"

    key = String.to_atom(key)

    case value do
      %{"type" => "string", "template" => template} when is_binary(template) and template != "" ->
        nil

      %{"type" => "string", "enum" => enum} when is_list(enum) ->
        options =
          if Map.get(value, "blank", false) do
            [{"", nil}] ++ Enum.map(enum, &{&1, &1})
          else
            Enum.map(enum, &{&1, &1})
          end

        %{
          type: "select",
          key: key,
          name: name,
          id: id,
          label: title,
          options: options
        }

      %{"type" => "string", "format" => "uuid", "reference" => reference} ->
        # FUTURE: Limit scope of which rooms they can see
        options =
          case reference do
            "inventory/rooms" ->
              opts
              |> HousingApp.Assignments.Room.list!()
              |> Enum.map(&{"#{&1.building.name} #{&1.name}", &1.id})

            _ ->
              []
          end

        %{
          type: "select",
          key: key,
          name: name,
          id: id,
          label: title,
          options: options
        }

      %{"type" => "string", "format" => "message"} ->
        # NOTE: Use `value["title"]` for label instead of `title` like all others since it isn't actually an input field
        %{
          type: "message",
          key: key,
          name: name,
          id: id,
          label: value["title"],
          value: value["description"]
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

      %{"type" => "array", "items" => %{"enum" => enum}} ->
        %{
          type: "select",
          key: key,
          name: "#{name}[]",
          id: id,
          label: title,
          multiple: true,
          options: Enum.map(enum, fn v -> {v, v} end)
        }

      %{"type" => "object"} ->
        %{type: "object", key: key, id: id, title: title, definitions: to_html_form_inputs(value, name)}

      _ ->
        nil
    end
  end

  def extract_properties(%{"properties" => properties}) when is_map(properties) do
    Enum.reduce(properties, %{}, fn {key, value}, acc ->
      case value do
        %{"template" => template} when is_binary(template) and template != "" ->
          acc

        %{"type" => type} when type in ["string", "integer", "boolean"] ->
          Map.put(acc, String.to_atom(key), String.to_atom(type))

        %{"type" => "array", "items" => %{"type" => type}} when type in ["string", "integer", "boolean"] ->
          Map.put(acc, String.to_atom(key), {:array, String.to_atom(type)})

        %{"type" => "array"} ->
          Map.put(acc, String.to_atom(key), {:array, :string})

        _ ->
          acc
      end
    end)
  end

  def extract_properties(%{}), do: []

  def cast_params(%{"properties" => properties} = schema, params) when is_map(properties) do
    types = extract_properties(schema)

    changeset = Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))

    converted =
      Enum.reduce(changeset.changes, %{}, fn {key, value}, acc -> Map.put(acc, Atom.to_string(key), value) end)

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

  def validate_against_schema do
    schema =
      Jason.decode!("""
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
      """)

    types =
      Enum.reduce(schema["properties"], %{}, fn {key, value}, acc ->
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
      |> Enum.map(&String.to_existing_atom/1)
      |> Enum.reject(fn key -> !Map.has_key?(types, key) end)

    # types = %{name: :string, email: :string, age: :integer}
    params = %{name: "Callum", email: "callum@example.com", age: "27"}
    param_strings = Enum.reduce(params, %{}, fn {key, value}, acc -> Map.put(acc, to_string(key), value) end)

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
