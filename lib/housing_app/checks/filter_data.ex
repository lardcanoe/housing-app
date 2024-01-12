defmodule HousingApp.Checks.FilterData do
  @moduledoc false

  # Example for chaining before_action and after_action: https://elixirforum.com/t/how-to-filter-using-a-code-interface/59060/8?u=lardcanoe
  def filter_records(query, _context) do
    # Note: context.actor
    #       query.tenant

    # TODO: Load json schema, and filter fields based on actor's roles

    Ash.Query.after_action(query, fn _query, records ->
      {:ok, Enum.map(records, &filter_record/1)}
    end)
  end

  def filter_record(record) do
    # struct(record, sanitized_data: Map.put(record.sanitized_data, "age", "***"))
    record
  end

  def merge_sanitized_data(changeset) do
    # NOTE: Ash.Changeset.add_error(changeset, "Could not update data")

    Ash.Changeset.before_action(changeset, fn changeset ->
      if changeset.attributes.sanitized_data do
        # FUTURE: Ensure that sanitized_data only contains the fields it is supposed to
        # 1. Merge sanitized into _data
        # 2. And then clear sanitized_data because it can't be saved to the db
        changeset
        |> Ash.Changeset.change_attribute(
          :_data,
          HousingApp.Utils.MapUtil.deep_merge(changeset.data._data, changeset.attributes.sanitized_data)
        )
        |> Ash.Changeset.clear_change(:sanitized_data)
      else
        changeset
      end
    end)
  end
end
