defmodule HousingAppWeb.Guardian do
  use Guardian, otp_app: :housing_app

  def subject_for_token(%{id: id}, _claims) do
    {:ok, id}
  end

  def subject_for_token(%{"id" => id}, _claims) do
    {:ok, id}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(%{"sub" => id}) do
    resource = HousingApp.Accounts.UserTenant.find_for_api!(id, authorize?: false)
    {:ok, resource}
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end
end
