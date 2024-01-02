defmodule HousingApp.Management.Correlation do
  @moduledoc false

  use Ash.Resource,
    data_layer: :embedded

  attributes do
    uuid_primary_key :id
    attribute :action, :string
    attribute :resource, :string
    attribute :resource_id, :uuid
  end
end
