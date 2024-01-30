defmodule HousingApp.Utils.Forms do
  @moduledoc false
  def update_position(current_pos, new_pos, old_pos) do
    current_pos =
      if is_binary(current_pos) do
        String.to_integer(current_pos)
      else
        current_pos
      end

    cond do
      current_pos == old_pos ->
        new_pos

      new_pos > old_pos and current_pos > old_pos and current_pos <= new_pos ->
        current_pos - 1

      new_pos < old_pos and current_pos >= new_pos and current_pos < old_pos ->
        current_pos + 1

      true ->
        current_pos
    end
  end

  def copy_resource(resource, source) do
    resource
    |> Ash.Resource.Info.public_attributes()
    |> Enum.reject(&(&1.name in [:id, :created_at, :updated_at, :archived_at]))
    |> Enum.reduce(%{}, fn %{name: name}, acc ->
      if name == :name do
        Map.put(acc, name, "#{Map.get(source, name)} (Copy)")
      else
        Map.put(acc, name, Map.get(source, name))
      end
    end)
  end
end
