defmodule HousingApp.Management.Permission do
  @moduledoc false

  use Ash.Resource,
    data_layer: :embedded

  attributes do
    uuid_primary_key :id

    attribute :resource, :atom do
      constraints one_of: [:form, :application, :profile]
      allow_nil? false
    end

    attribute :field, :string

    attribute :read, :boolean do
      default false
      allow_nil? false
    end

    attribute :write, :boolean do
      default false
      allow_nil? false
    end
  end

  identities do
    identity :unique_by_resource_and_field, [:resource, :field]
  end
end
