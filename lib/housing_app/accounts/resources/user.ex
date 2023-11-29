defmodule HousingApp.Accounts.User do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication, AshAdmin.Resource]

  authentication do
    api HousingApp.Accounts

    strategies do
      password :password do
        identity_field(:email)
        hashed_password_field(:hashed_password)
        sign_in_tokens_enabled?(true)
        confirmation_required?(false)
        register_action_accept([:email])

        resettable do
          sender HousingApp.Accounts.User.Senders.SendPasswordResetEmail
        end
      end
    end

    tokens do
      enabled? true
      token_resource HousingApp.Accounts.Token

      signing_secret fn _, _ ->
        Application.fetch_env(:housing_app, :token_signing_secret)
      end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string, allow_nil?: false
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true

    attribute :role, :atom do
      constraints one_of: [:user, :platform_admin]
      default :user
      allow_nil? false
    end

    attribute :name, :string, constraints: [trim?: true]
    attribute :avatar, :string, constraints: [trim?: true]

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  admin do
    actor?(true)
  end

  relationships do
    has_many :user_tenants, HousingApp.Accounts.UserTenant
  end

  postgres do
    table "users"
    repo HousingApp.Repo

    references do
      reference :user_tenants, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :update]
  end

  code_interface do
    define_for HousingApp.Accounts
  end

  identities do
    identity :unique_email, [:email]
  end

  validations do
    validate match(:email, ~r/@/)
    validate string_length(:email, min: 6, max: 200)
  end
end
