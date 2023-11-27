defmodule HousingApp.Checks.IsTenantAdmin do
  use Ash.Policy.SimpleCheck

  # This is used when logging a breakdown of how a policy is applied - see Logging below.
  def describe(_) do
    "actor is tenant admin"
  end

  def match?(
        %HousingApp.Accounts.UserTenant{role: role},
        _context,
        _opts
      ) do
    role == :admin
  end

  def match?(_, _, _), do: false
end
