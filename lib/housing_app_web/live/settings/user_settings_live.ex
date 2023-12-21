defmodule HousingAppWeb.Live.Settings.UserSettings do
  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  # https://flowbite.com/blocks/application/crud-update-forms/#update-user-form
  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div class="max-w-2xl px-4 py-8 mx-auto lg:py-16">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update user</h2>
      <.simple_form for={@user_form} phx-change="validate" autowidth={false} phx-submit="submit-user">
        <.input field={@user_form[:name]} label="Name" />
        <.input field={@user_form[:email]} label="Email" />
        <:actions>
          <.button>Save</.button>
          <.button :if={false} type="delete">Delete</.button>
        </:actions>
      </.simple_form>

      <%= render_ui(assigns) %>

      <.json_form
        :if={@profile_form}
        class="mt-6"
        form={@profile_form}
        json_schema={@json_schema}
        autowidth={false}
        prefix="profile"
      />
    </div>
    """
  end

  defp render_ui(assigns) do
    ~H"""
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
    """
  end

  def mount(
        _params,
        _session,
        %{
          assigns: %{
            current_user_tenant: %{user_type: :user} = current_user_tenant,
            current_user: current_user,
            current_tenant: tenant
          }
        } = socket
      ) do
    with {:ok, profile} <-
           HousingApp.Management.Profile.get_by_user_tenant(current_user_tenant.id,
             actor: current_user_tenant,
             tenant: tenant
           ),
         {:ok, profile_form} <- HousingApp.Management.get_profile_form(actor: current_user_tenant, tenant: tenant) do
      {:ok,
       assign(socket,
         json_schema: profile_form.json_schema |> Jason.decode!(),
         profile: profile,
         profile_form: profile.data |> to_form(as: "profile"),
         user_form: user_form(current_user),
         page_title: "Profile Settings"
       )
       |> push_event("init-dark-mode", %{})}
    else
      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Profile not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  def mount(_params, _session, %{assigns: %{current_user: current_user}} = socket) do
    {:ok,
     assign(socket, user_form: user_form(current_user), profile_form: nil, page_title: "Profile Settings")
     |> push_event("init-dark-mode", %{})}
  end

  defp user_form(current_user) do
    current_user
    |> AshPhoenix.Form.for_update(:update,
      api: HousingApp.Accounts,
      forms: [auto?: true]
    )
    |> to_form()
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params)}
  end

  def handle_event("validate", %{"profile" => _params}, socket) do
    {:noreply, socket}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    user_form = AshPhoenix.Form.validate(socket.assigns.user_form, params)
    {:noreply, assign(socket, user_form: user_form)}
  end

  def handle_event("submit-user", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.user_form, params: params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully updated your profile.")}

      {:error, user_form} ->
        {:noreply, assign(socket, user_form: user_form)}
    end
  end

  def handle_event(
        "submit",
        %{"profile" => data},
        %{
          assigns: %{
            json_schema: json_schema,
            profile: profile,
            current_user_tenant: current_user_tenant,
            current_tenant: tenant
          }
        } = socket
      ) do
    with data <- HousingApp.Utils.JsonSchema.cast_params(json_schema, data),
         ref_schema <- ExJsonSchema.Schema.resolve(json_schema),
         :ok <- ExJsonSchema.Validator.validate(ref_schema, data),
         {:ok, profile} <-
           HousingApp.Management.Profile.submit(profile, %{data: data}, actor: current_user_tenant, tenant: tenant) do
      {:noreply,
       socket
       |> assign(
         profile: profile,
         profile_form: data |> to_form(as: "profile")
       )
       |> put_flash(:info, "Updated profile")}
    else
      {:error, _errors} ->
        {:noreply, socket |> put_flash(:error, "Errors present in form submission.")}
    end
  end
end
