defmodule HousingApp.Management.ApplicationStep do
  @moduledoc false

  use Ash.Resource,
    data_layer: :embedded

  attributes do
    uuid_primary_key :id

    attribute :step, :integer do
      allow_nil? false
    end

    attribute :title, :string do
      constraints min_length: 1, trim?: true
      allow_nil? false
    end

    attribute :required, :boolean do
      default false
      allow_nil? false
    end
  end

  relationships do
    belongs_to :form, HousingApp.Management.Form do
      attribute_writable? true
      allow_nil? false
    end
  end

  identities do
    identity :unique_by_step, [:step]
  end
end
