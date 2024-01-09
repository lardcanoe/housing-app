defmodule HousingApp.Management.ApplicationCondition do
  @moduledoc false

  use Ash.Resource,
    data_layer: :embedded

  attributes do
    uuid_primary_key :id
  end

  relationships do
    belongs_to :common_query, HousingApp.Management.CommonQuery do
      attribute_writable? true
      allow_nil? false
    end
  end
end
