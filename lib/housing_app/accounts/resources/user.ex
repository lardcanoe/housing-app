defmodule HousingApp.Accounts.User do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication, AshAdmin.Resource]

  authentication do
    api HousingApp.Accounts

    strategies do
      password :password do
        identity_field(:email)
        hashed_password_field(:hashed_password)
        sign_in_tokens_enabled?(true)
        confirmation_required?(false)
        register_action_accept([:email, :name])

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

  relationships do
    has_many :user_tenants, HousingApp.Accounts.UserTenant
  end

  admin do
    actor?(true)
  end

  policies do
    bypass always() do
      authorize_if always()
    end

    # bypass always() do
    #   authorize_if HousingApp.Checks.IsPlatformAdmin
    # end

    # policy action(:read) do
    #   authorize_if expr(id == ^actor(:id))
    # end

    # policy action(:update) do
    #   description "A logged in user can update themselves."
    #   authorize_if expr(id == ^actor(:id))
    # end

    # policy action(:update_email) do
    #   description("A logged in user can update their email")
    #   authorize_if(expr(id == ^actor(:id)))
    # end

    # policy action(:resend_confirmation_instructions) do
    #   description("A logged in user can request an email confirmation")
    #   authorize_if(expr(id == ^actor(:id)))
    # end

    # policy action(:change_password) do
    #   description("A logged in user can reset their password")
    #   authorize_if(expr(id == ^actor(:id)))
    # end
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

    # action :sign_out, :integer do
    #   argument :user, MyApp.User, allow_nil?: false

    #   run fn input, _ ->
    #     subject = AshAuthentication.user_to_subject(input.arguments.user)

    #     import Ecto.Query

    #     query = from t in MyApp.Token,
    #       where: t.subject == ^subject

    #     {count, _} = MyApp.Repo.delete_all(query)
    #     {:ok, count}
    #   end
    # end
  end

  code_interface do
    define_for HousingApp.Accounts
  end

  identities do
    identity :unique_email, [:email]
  end

  validations do
    validate match(:email, ~r/^[^\s]+@[^\s]+$/), message: "must have the @ sign and no spaces"
    validate string_length(:email, min: 6, max: 200)
  end
end
