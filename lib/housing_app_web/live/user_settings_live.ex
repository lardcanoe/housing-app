defmodule HousingAppWeb.Live.UserSettingsLive do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  # https://flowbite.com/blocks/application/crud-update-forms/#update-user-form
  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.simple_form for={@form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update profile</h2>
      <.input field={@form[:name]} label="Name" />
      <:actions>
        <.button>Save</.button>
        <.button :if={false} type="delete">Delete</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user: current_user}} = socket) do
    form =
      current_user
      |> AshPhoenix.Form.for_update(:update,
        api: HousingApp.Accounts,
        forms: [auto?: true]
      )
      |> to_form()

    {:ok, assign(socket, form: form, page_title: "Profile Settings")}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully updated your profile.")}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end
end
