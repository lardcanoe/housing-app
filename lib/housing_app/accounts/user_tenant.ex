defmodule HousingApp.Accounts.UserTenant do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_tenants" do
    # field :user_id, :binary
    # field :tenant_id, :binary

    field :role, :string, default: "user"

    belongs_to :tenant, HousingApp.Accounts.Tenant
    belongs_to :user, HousingApp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_tenant, attrs) do
    user_tenant
    |> cast(attrs, [:user_id, :tenant_id, :role])
    |> validate_required([:user_id, :tenant_id])
    |> validate_inclusion(:role, ~w(user admin))
  end
end
