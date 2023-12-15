defmodule HousingAppWeb.Live.UserSettingsLive do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  # https://flowbite.com/blocks/application/crud-update-forms/#update-user-form
  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div class="max-w-2xl px-4 py-8 mx-auto lg:py-16">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update profile</h2>
      <.simple_form for={@ash_form} phx-change="validate" autowidth={false} phx-submit="submit">
        <.input field={@ash_form[:name]} label="Name" />
        <.input field={@ash_form[:email]} label="Email" />
        <:actions>
          <.button>Save</.button>
          <.button :if={false} type="delete">Delete</.button>
        </:actions>
      </.simple_form>

      <h2 class="mt-6 text-xl font-bold text-gray-900 dark:text-white">UI Settings</h2>
      <span class="mr-2 text-gray-900 dark:text-white">Toggle Dark Mode:</span>
      <button
        id="theme-toggle"
        type="button"
        class="text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 focus:outline-none focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-700 rounded-lg text-sm p-2.5"
      >
        <svg
          id="theme-toggle-dark-icon"
          class="hidden w-5 h-5"
          fill="currentColor"
          viewBox="0 0 20 20"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"></path>
        </svg>
        <svg
          id="theme-toggle-light-icon"
          class="hidden w-5 h-5"
          fill="currentColor"
          viewBox="0 0 20 20"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"
            fill-rule="evenodd"
            clip-rule="evenodd"
          >
          </path>
        </svg>
      </button>
    </div>
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

    {:ok, assign(socket, ash_form: ash_form, page_title: "Profile Settings") |> push_event("init-dark-mode", %{})}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
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
