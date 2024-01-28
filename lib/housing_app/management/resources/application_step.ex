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

    attribute :component, :atom do
      constraints one_of: [:assignments_select_bed, :management_update_profile]
      allow_nil? true
    end

    attribute :required, :boolean do
      default false
      allow_nil? false
    end
  end

  relationships do
    belongs_to :form, HousingApp.Management.Form do
      attribute_writable? true
      allow_nil? true
    end

    belongs_to :selection_process, HousingApp.Assignments.SelectionProcess do
      attribute_writable? true
      allow_nil? true
    end
  end

  identities do
    identity :unique_by_step, [:step]
  end

  preparations do
    prepare build(sort: [:step])
  end

  validations do
    validate present([:component, :form_id], exactly: 1)
  end
end
