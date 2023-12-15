defmodule HousingAppWeb.Live.Profiles.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.data_grid
      id="ag-data-grid"
      header="Profiles"
      count={@count}
      loading={@loading}
      drawer={HousingAppWeb.Components.Drawer.Profile}
      current_user_tenant={@current_user_tenant}
      current_tenant={@current_tenant}
    >
      <:actions>
        <.link patch={~p"/profiles/new"}>
          <button
            type="button"
            class="w-full md:w-auto flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-3 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <.icon name="hero-plus-small-solid" class="w-4 h-4 mr-2" /> Add profile
          </button>
        </.link>
      </:actions>
    </.data_grid>
    """
  end

  def mount(_params, _session, %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket) do
    case HousingApp.Management.get_profile_form(actor: current_user_tenant, tenant: tenant) do
      {:ok, profile_form} ->
        {:ok,
         assign(socket, profile_form: profile_form, loading: true, count: 0, sidebar: :profiles, page_title: "Profiles")}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Error loading profile form.")
         |> push_navigate(~p"/")}
    end
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params, loading: true, count: 0, sidebar: :profiles, page_title: "Profiles")}
  end

  def handle_event("view-row", %{"id" => id}, socket) do
    send_update(HousingAppWeb.Components.Drawer.Profile, id: "drawer-right", profile_id: id)
    {:noreply, socket}
  end

  def handle_event("edit-row", %{"id" => id}, socket) do
    {:noreply, socket |> push_navigate(to: ~p"/profiles/#{id}/edit")}
  end

  def handle_event(
        "load-data",
        %{},
        %{assigns: %{profile_form: profile_form, current_user_tenant: current_user_tenant, current_tenant: tenant}} =
          socket
      ) do
    profiles =
      HousingApp.Management.Profile.list!(actor: current_user_tenant, tenant: tenant)
      |> Enum.sort_by(& &1.user_tenant.user.name)
      |> Enum.map(fn p ->
        Map.merge(
          p.data,
          %{
            "id" => p.id,
            "user_name" => p.user_tenant.user.name,
            "user_email" => p.user_tenant.user.email,
            "actions" => [["Edit"], ["View"]]
          }
        )
      end)

    schema = profile_form.json_schema |> Jason.decode!()

    columns =
      [
        %{
          field: "user_name",
          headerName: "User",
          minWidth: 160,
          pinned: "left",
          checkboxSelection: true,
          headerCheckboxSelection: true
        },
        %{field: "id", minWidth: 120, pinned: "left", hide: true},
        %{field: "user_email", headerName: "Email", minWidth: 160}
      ] ++
        HousingApp.Utils.JsonSchema.schema_to_aggrid_columns(schema) ++
        [
          %{
            field: "actions",
            pinned: "right",
            minWidth: 120,
            maxWidth: 120,
            filter: false,
            editable: false,
            sortable: false,
            resizable: false
          }
        ]

    {:reply,
     %{
       columns: columns,
       data: profiles
     }, assign(socket, loading: false, count: length(profiles))}
  end
end
