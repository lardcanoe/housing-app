defmodule HousingAppWeb.Live.Profiles.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  import HousingAppWeb.Components.DataGrid

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

  def mount(_params, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Management.Service.get_profile_form(actor: current_user_tenant, tenant: tenant) do
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
    {:noreply, push_navigate(socket, to: ~p"/profiles/#{id}/edit")}
  end

  def handle_event("load-data", %{}, %{assigns: %{profile_form: profile_form}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    profiles =
      [actor: current_user_tenant, tenant: tenant]
      |> HousingApp.Management.Profile.list!()
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

    schema = Jason.decode!(profile_form.json_schema)

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
