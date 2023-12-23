defmodule HousingAppWeb.Api.Guardian do
  @moduledoc false
  use Guardian, otp_app: :housing_app

  def subject_for_token(%{api_key: api_key}, _claims) when is_binary(api_key) and api_key != "" do
    {:ok, api_key}
  end

  def subject_for_token(%{"api_key" => api_key}, _claims) when is_binary(api_key) and api_key != "" do
    {:ok, api_key}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(%{"sub" => api_key}) do
    case HousingApp.Accounts.UserTenant.get_by_api_key(api_key, authorize?: false) do
      {:ok, resource} -> {:ok, resource}
      _ -> {:error, :reason_for_error}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end
end
