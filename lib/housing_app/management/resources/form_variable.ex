defmodule HousingApp.Management.FormVariable do
  @moduledoc false

  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :name, :string do
      constraints min_length: 1, trim?: true
      allow_nil? false
    end

    attribute :value, :string
  end

  identities do
    identity :unique_by_name, [:name]
  end
end
