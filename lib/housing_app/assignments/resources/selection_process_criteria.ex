defmodule HousingApp.Assignments.SelectionProcessCriteria do
  @moduledoc false

  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :index, :integer do
      allow_nil? false
    end
  end

  relationships do
    belongs_to :criteria, HousingApp.Assignments.SelectionCriteria do
      allow_nil? false
      attribute_writable? true
    end
  end

  identities do
    identity :unique_by_criteria, [:criteria_id]
    identity :unique_by_index, [:index]
  end

  preparations do
    prepare build(sort: [:index])
  end

  multitenancy do
    strategy :context
  end
end
