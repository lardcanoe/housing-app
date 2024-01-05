defmodule HousingApp.Accounts.Service do
  @moduledoc false

  # FUTURE: Handle an archived user or user_tenant
  def invite_user_to_tenant(email, name, user_type, actor: actor) do
    with {:ok, user} <- find_or_create_user(email, name, actor: actor),
         {:ok, user_tenant} <- find_or_create_user_tenant(user, user_type, actor: actor) do
      {:ok, user_tenant}
    else
      {:error, err} ->
        dbg(err)
        {:error, "Failed to invite user"}
    end
  end

  defp find_or_create_user(email, name, actor: actor) do
    case HousingApp.Accounts.User.get_by_email(email, actor: actor) do
      {:ok, user} ->
        {:ok, user}

      {:error, _} ->
        # FUTURE: Remove need for a random password. Leave blank, and send magic link
        random_pw = HousingApp.Utils.Random.Token.generate()

        HousingApp.Accounts.User
        |> Ash.Changeset.for_create(
          :register_with_password,
          %{
            "name" => name,
            "email" => email,
            "password" => random_pw,
            "password_confirmation" => random_pw
          },
          actor: actor
        )
        |> HousingApp.Accounts.create()
    end
  end

  defp find_or_create_user_tenant(user, user_type, actor: actor) do
    case HousingApp.Accounts.UserTenant.get_for_user_of_my_tenant(user.id, actor: actor) do
      {:ok, user_tenant} ->
        {:ok, user_tenant}

      {:error, _} ->
        create_user_tenant(user, user_type, actor: actor)
    end
  end

  defp create_user_tenant(user, user_type, actor: actor) do
    HousingApp.Accounts.UserTenant
    |> Ash.Changeset.for_create(
      :create,
      %{
        user_id: user.id,
        tenant_id: actor.tenant_id,
        user_type: user_type
      },
      actor: actor
    )
    |> HousingApp.Accounts.create()
  end
end
