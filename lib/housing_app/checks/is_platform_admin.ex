defmodule HousingApp.Checks.IsPlatformAdmin do
  @moduledoc false
  use Ash.Policy.SimpleCheck

  # This is used when logging a breakdown of how a policy is applied - see Logging below.
  def describe(_) do
    "actor is platform admin"
  end

  def match?(%HousingApp.Accounts.UserTenant{user: %HousingApp.Accounts.User{role: :platform_admin}}, _context, _opts) do
    true
  end

  def match?(_, _, _), do: false
end
