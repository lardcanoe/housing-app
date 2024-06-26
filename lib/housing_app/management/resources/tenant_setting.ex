defmodule HousingApp.Management.TenantSetting do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Api],
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    attribute :namespace, :atom do
      primary_key? true
      allow_nil? false
    end

    attribute :setting, :atom do
      primary_key? true
      allow_nil? false
    end

    attribute :value, :string do
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  admin do
    show?(true)
  end

  relationships do
  end

  policies do
    bypass always() do
      authorize_if HousingApp.Checks.IsPlatformAdmin
      authorize_if HousingApp.Checks.IsTenantAdmin
      authorize_if action_type(:read)
    end
  end

  postgres do
    table "tenant_settings"
    repo HousingApp.Repo
  end

  actions do
    defaults [:create, :read, :update]

    read :list_settings do
      prepare build(select: [:namespace, :setting, :value])
    end

    read :get_setting do
      argument :namespace, :atom do
        allow_nil? false
      end

      argument :setting, :atom do
        allow_nil? false
      end

      get? true

      filter expr(namespace == ^arg(:namespace) and setting == ^arg(:setting))
    end

    action :get_settings, :map do
      run fn input, context ->
        map =
          [actor: context.actor]
          |> __MODULE__.list_settings!()
          |> Enum.map(fn entry ->
            {{entry.namespace, entry.setting}, entry.value}
          end)
          |> Map.new()

        {:ok, map}
      end
    end

    create :update_setting do
      accept [:namespace, :setting, :value]
      upsert? true
    end
  end

  code_interface do
    define_for HousingApp.Management

    define :list_settings
    define :get_setting, args: [:namespace, :setting]
    define :update_setting
    define :get_settings
  end

  identities do
    identity :unique_namespace_setting, [:namespace, :setting]
  end

  multitenancy do
    strategy :context
  end
end
