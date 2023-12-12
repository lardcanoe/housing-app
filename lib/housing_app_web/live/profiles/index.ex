defmodule HousingAppWeb.Live.Profiles.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <.data_grid id="ag-data-grid" header="Profiles" count={@count} loading={@loading}>
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
    {:ok, assign(socket, loading: true, count: 0, sidebar: :profiles, page_title: "Profiles")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, params: params, loading: true, count: 0, sidebar: :profiles, page_title: "Profiles")}
  end

  def handle_event(
        "load-data",
        %{},
        %{assigns: %{current_user_tenant: current_user_tenant, current_tenant: tenant}} = socket
      ) do
    profiles =
      HousingApp.Management.Profile.list!(actor: current_user_tenant, tenant: tenant)
      |> Enum.sort_by(& &1.user_tenant.user.name)
      |> Enum.map(fn p ->
        %{
          "id" => p.id,
          "name" => p.user_tenant.user.name,
          "email" => p.user_tenant.user.email,
          "actions" => [["Edit", ~p"/profiles/#{p.id}/edit"]]
        }
      end)

    columns =
      if current_user_tenant.user.role == :platform_admin do
        [
          %{field: "id", minWidth: 120, pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
          %{field: "name", minWidth: 160, pinned: "left"},
          %{field: "email", minWidth: 160},
          %{
            field: "actions",
            pinned: "right",
            maxWidth: 90,
            filter: false,
            editable: false,
            sortable: false,
            resizable: false
          }
        ]
      else
        [
          %{field: "name", minWidth: 160, pinned: "left", checkboxSelection: true, headerCheckboxSelection: true},
          %{field: "email", minWidth: 160},
          %{
            field: "actions",
            pinned: "right",
            maxWidth: 90,
            filter: false,
            editable: false,
            sortable: false,
            resizable: false
          }
        ]
      end

    {:reply,
     %{
       columns: columns,
       data: profiles
     }, assign(socket, loading: false, count: length(profiles))}
  end
end
