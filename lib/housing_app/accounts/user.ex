defmodule HousingApp.Accounts.User do
  @moduledoc false

  use Ecto.Schema
  use Pow.Ecto.Schema
  import Ecto.Changeset
  import HousingAppWeb.Gettext

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    pow_user_fields()

    field :role, :string, default: "user"

    has_many :user_tenants, HousingApp.Accounts.UserTenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec registration_changeset(Ecto.Schema.t(), map(), Keyword.t()) :: Ecto.Changeset.t()
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :email,
      :role
    ])
    |> validate_user_email(opts)
    |> validate_inclusion(:role, ~w(user platform_admin))
  end

  defp validate_email(changeset, field) do
    changeset
    |> validate_format(field, ~r/^[^\s]+@[^\s]+$/,
      message: dgettext("errors", "must have the @ sign and no spaces")
    )
    |> validate_format(field, ~r/^[^\s]+@[^\s]+\.[^\s]+$/,
      message: dgettext("errors", "must have a domain name")
    )
    |> validate_length(field, max: 160)
  end

  defp validate_user_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_email(:email)
    |> maybe_validate_unique_email(opts)
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, HousingApp.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end
end
