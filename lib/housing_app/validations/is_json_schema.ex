defmodule HousingApp.Validations.IsJsonSchema do
  @moduledoc false

  use Ash.Resource.Validation

  @impl true
  def init(opts) do
    if is_atom(opts[:attribute]) do
      {:ok, opts}
    else
      {:error, "attribute must be an atom!"}
    end
  end

  @impl true
  def validate(changeset, opts) do
    value = Ash.Changeset.get_attribute(changeset, opts[:attribute])

    if is_nil(value) do
      :ok
    else
      ExJsonSchema.Schema.resolve(Jason.decode!(value))
      :ok
    end
  rescue
    Jason.DecodeError ->
      {:error, field: opts[:attribute], message: "must be valid JSON."}

    ExJsonSchema.Schema.InvalidSchemaError ->
      {:error, field: opts[:attribute], message: "must be a valid JSON schema."}
  end
end
