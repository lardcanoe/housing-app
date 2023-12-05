defmodule HousingAppWeb.Live.UserSettingsLive do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  # https://flowbite.com/blocks/application/crud-update-forms/#update-user-form
  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update profile</h2>
      <.input field={@ash_form[:name]} label="Name" />
      <.input field={@ash_form[:email]} label="Email" />
      <:actions>
        <.button>Save</.button>
        <.button :if={false} type="delete">Delete</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user: current_user}} = socket) do
    ash_form =
      current_user
      |> AshPhoenix.Form.for_update(:update,
        api: HousingApp.Accounts,
        forms: [auto?: true]
      )
      |> to_form()

    {:ok, assign(socket, ash_form: ash_form, page_title: "Profile Settings")}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully updated your profile.")}

      {:error, ash_form} ->
        {:noreply, assign(socket, ash_form: ash_form)}
    end
  end
end
