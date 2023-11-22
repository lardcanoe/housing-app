defmodule HousingApp.Accounts.Tenant do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tenants" do
    field :name, :string

    has_many :user_tenants, HousingApp.Accounts.UserTenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
