defmodule HousingAppWeb.Live.Assignments.Roles.Form do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{for_user_type: "student", live_action: :new} = assigns) do
    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Student / Role Query</h2>

      <.async_result :let={user_tenants} assign={@user_tenants}>
        <:loading>
          <.input
            type="select"
            field={@ash_form[:user_tenant_id]}
            options={[]}
            label="Student"
            prompt="Loading students..."
            disabled
          />
        </:loading>
        <:failed :let={reason}><%= reason %></:failed>
        <.input
          type="select"
          field={@ash_form[:user_tenant_id]}
          options={user_tenants}
          label="Student"
          prompt="Select a student..."
          required
        />
      </.async_result>

      <.async_result :let={roles} assign={@roles}>
        <:loading>
          <.input type="select" field={@ash_form[:role_id]} options={[]} label="Role" prompt="Loading roles..." disabled />
        </:loading>
        <:failed :let={reason}><%= reason %></:failed>
        <.input type="select" field={@ash_form[:role_id]} options={roles} label="Role" prompt="Select a role..." required />
      </.async_result>

      <.async_result :let={time_periods} assign={@time_period_options}>
        <:loading>
          <.input
            type="select"
            field={@ash_form[:time_period_id]}
            options={[]}
            label="Time Period"
            prompt="Loading time periods..."
            disabled
          />
        </:loading>
        <:failed :let={reason}><%= reason %></:failed>
        <.input
          type="select"
          field={@ash_form[:time_period_id]}
          options={time_periods}
          label="Time Period"
          prompt="Select a time period..."
          required
        />
      </.async_result>

      <.async_result :let={common_queries} assign={@common_queries}>
        <:loading>
          <.input
            type="select"
            field={@ash_form[:common_query_id]}
            options={[]}
            label="Query"
            disabled
            prompt="Loading queries..."
          />
        </:loading>
        <:failed :let={reason}><%= reason %></:failed>
        <.input
          type="select"
          field={@ash_form[:common_query_id]}
          options={common_queries}
          label="Query"
          prompt="Select a common query..."
          required
        />
      </.async_result>

      <:actions>
        <.button>Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def render(%{live_action: live_action} = assigns) do
    assigns = assign(assigns, action: live_action)

    ~H"""
    <.simple_form for={@ash_form} phx-change="validate" phx-submit="submit">
      <h2 :if={@action == :new} class="mb-4 text-xl font-bold text-gray-900 dark:text-white">New Role Query</h2>
      <h2 :if={@action == :edit} class="mb-4 text-xl font-bold text-gray-900 dark:text-white">Update Role Query</h2>

      <.async_result :let={user_tenant_roles} assign={@user_tenant_roles}>
        <:loading>
          <.input
            type="select"
            field={@ash_form[:user_tenant_role_id]}
            options={[]}
            label="User / Role"
            prompt="Loading user roles..."
            disabled
          />
        </:loading>
        <:failed :let={reason}><%= reason %></:failed>
        <.input
          type="select"
          field={@ash_form[:user_tenant_role_id]}
          options={user_tenant_roles}
          label="User / Role"
          prompt="Select a user-role pair..."
          {if(@action == :new, do: [{"required",""}], else: [])}
          {if(@action == :edit, do: [{"disabled",""}], else: [])}
        />
      </.async_result>

      <.async_result :let={common_queries} assign={@common_queries}>
        <:loading>
          <.input
            type="select"
            field={@ash_form[:common_query_id]}
            options={[]}
            label="Query"
            disabled
            prompt="Loading queries..."
          />
        </:loading>
        <:failed :let={reason}><%= reason %></:failed>
        <.input
          type="select"
          field={@ash_form[:common_query_id]}
          options={common_queries}
          label="Query"
          prompt="Select a common query..."
          {if(@action == :new, do: [{"required",""}], else: [])}
        />
      </.async_result>

      <:actions>
        <.button :if={@action == :new}>Create</.button>
        <.button :if={@action == :edit}>Save</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Assignments.RoleQuery.get_by_id(id, actor: current_user_tenant, tenant: tenant) do
      {:error, _} ->
        {:ok,
         socket
         |> assign(sidebar: :assignments)
         |> put_flash(:error, "Not found")
         |> push_navigate(to: ~p"/assignments/roles")}

      {:ok, app} ->
        ash_form =
          app
          |> AshPhoenix.Form.for_update(:update,
            api: HousingApp.Assignments,
            forms: [auto?: true],
            actor: current_user_tenant,
            tenant: tenant
          )
          |> to_form()

        {:ok,
         socket
         |> assign(
           ash_form: ash_form,
           sidebar: :assignments,
           page_title: "Edit Role Query"
         )
         |> load_async_assigns()}
    end
  end

  def mount(%{"for" => "student"}, _session, socket) do
    {:ok,
     socket
     |> assign(
       for_user_type: "student",
       ash_form: to_form(%{"user_tenant_id" => nil}, as: "student_form"),
       sidebar: :assignments,
       page_title: "New Student Role Query"
     )
     |> load_async_assigns()}
  end

  def mount(_params, _session, socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    ash_form =
      HousingApp.Assignments.RoleQuery
      |> AshPhoenix.Form.for_create(:new,
        api: HousingApp.Assignments,
        forms: [auto?: true],
        actor: current_user_tenant,
        tenant: tenant
      )
      |> to_form()

    {:ok,
     socket
     |> assign(
       for_user_type: "staff",
       ash_form: ash_form,
       sidebar: :assignments,
       page_title: "New Role Query"
     )
     |> load_async_assigns()}
  end

  def load_async_assigns(%{assigns: %{for_user_type: "student"}} = socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    assign_async(socket, [:user_tenants, :roles, :time_periods, :time_period_options, :common_queries], fn ->
      user_tenants =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Accounts.UserTenant.list_students!()
        |> Enum.sort_by(& &1.user.name)
        |> Enum.map(fn ut ->
          {"#{ut.user.name} (#{ut.user.email})", ut.id}
        end)

      roles =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Management.Role.list!()
        |> Enum.map(&{&1.name, &1.id})
        |> Enum.sort_by(fn {name, _} -> name end)

      time_periods = HousingApp.Management.TimePeriod.list!(actor: current_user_tenant, tenant: tenant)

      time_period_options =
        time_periods
        |> Enum.map(&{&1.name, &1.id})
        |> Enum.sort_by(fn {name, _} -> name end)

      common_queries =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Management.CommonQuery.list!()
        |> Enum.map(&{&1.name, &1.id})
        |> Enum.sort_by(fn {name, _} -> name end)

      {:ok,
       %{
         user_tenants: user_tenants,
         roles: roles,
         time_periods: time_periods,
         time_period_options: time_period_options,
         common_queries: common_queries
       }}
    end)
  end

  def load_async_assigns(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    assign_async(socket, [:user_tenant_roles, :common_queries], fn ->
      user_tenant_roles =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Management.UserTenantRole.list!()
        |> Enum.sort_by(& &1.user_tenant.user.name)
        |> Enum.map(fn utr ->
          if is_nil(utr.time_period) do
            {"#{utr.user_tenant.user.name}, Role: #{utr.role.name}", utr.id}
          else
            {"#{utr.user_tenant.user.name}, Role: #{utr.role.name} [#{utr.time_period.name}]", utr.id}
          end
        end)

      common_queries =
        [actor: current_user_tenant, tenant: tenant]
        |> HousingApp.Management.CommonQuery.list!()
        |> Enum.map(&{&1.name, &1.id})
        |> Enum.sort_by(fn {name, _} -> name end)

      {:ok, %{user_tenant_roles: user_tenant_roles, common_queries: common_queries}}
    end)
  end

  def handle_event("validate", %{"student_form" => _params}, socket) do
    {:noreply, socket}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    ash_form = AshPhoenix.Form.validate(socket.assigns.ash_form, params)
    {:noreply, assign(socket, ash_form: ash_form)}
  end

  def handle_event(
        "submit",
        %{
          "student_form" => %{
            "common_query_id" => common_query_id,
            "role_id" => role_id,
            "time_period_id" => time_period_id,
            "user_tenant_id" => user_tenant_id
          }
        },
        socket
      ) do
    %{time_periods: time_periods, current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    time_period = Enum.find(time_periods.result, &(&1.id == time_period_id))

    {:ok, utr} =
      HousingApp.Management.UserTenantRole.new(
        %{
          user_tenant_id: user_tenant_id,
          role_id: role_id,
          time_period_id: time_period_id,
          start_at: time_period.start_at,
          end_at: time_period.end_at
        },
        tenant: tenant,
        actor: current_user_tenant
      )

    {:ok, _rq} =
      HousingApp.Assignments.RoleQuery.new(
        %{
          user_tenant_role_id: utr.id,
          common_query_id: common_query_id
        },
        tenant: tenant,
        actor: current_user_tenant
      )

    {:noreply,
     socket
     |> put_flash(:info, "Successfully created the role query.")
     |> push_navigate(to: ~p"/assignments/roles")}
  end

  def handle_event("submit", %{"form" => params}, %{assigns: %{live_action: action}} = socket) do
    case AshPhoenix.Form.submit(socket.assigns.ash_form, params: params) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           if(action == :new, do: "Successfully created the role query.", else: "Successfully updated the role query.")
         )
         |> push_navigate(to: ~p"/assignments/roles")}

      {:error, ash_form} ->
        IO.inspect(ash_form, label: "ash_form :error")

        {:noreply,
         socket
         |> assign(ash_form: ash_form)
         |> put_flash(
           :error,
           if(action == :new,
             do: "Failed to create role query due to internal errors.",
             else: "Failed to update role query due to internal errors."
           )
         )}
    end
  end
end
