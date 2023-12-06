# defmodule HousingApp.Management.FormSubmission do
#   @moduledoc false

#   use Ash.Resource,
#     data_layer: AshPostgres.DataLayer,
#     extensions: [AshArchival.Resource, AshAdmin.Api]

#   # authorizers: [Ash.Policy.Authorizer]

#   attributes do
#     uuid_primary_key :id

#     attribute :data, :map do
#       allow_nil? false
#     end

#     create_timestamp :created_at
#     update_timestamp :updated_at
#   end

#   admin do
#     show?(true)
#   end

#   relationships do
#     # Tenant is duplicate data, but makes it safer and easier to do data dumps
#     belongs_to :tenant, HousingApp.Accounts.Tenant do
#       api HousingApp.Accounts
#       attribute_writable? true
#       allow_nil? false
#     end

#     belongs_to :user_tenant, HousingApp.Accounts.UserTenant do
#       api HousingApp.Accounts
#       attribute_writable? true
#       allow_nil? false
#     end

#     belongs_to :form, HousingApp.Management.Form do
#       attribute_writable? true
#       allow_nil? false
#     end
#   end

#   # policies do
#   #   bypass always() do
#   #     authorize_if HousingApp.Checks.IsPlatformAdmin
#   #     authorize_if HousingApp.Checks.IsTenantAdmin
#   #   end

#   #   policy action_type(:read) do
#   #     authorize_if always()
#   #   end
#   # end

#   postgres do
#     table "form_submissions"
#     repo HousingApp.Repo
#   end

#   actions do
#     defaults [:create, :read, :update, :destroy]

#     # create :new do
#     #   accept [:name, :description, :json_schema]

#     #   argument :tenant_id, :uuid do
#     #     allow_nil? false
#     #   end

#     #   change manage_relationship(:tenant_id, :tenant, type: :append_and_remove)
#     # end

#     # read :list do
#     #   prepare build(select: [:id, :name, :description, :status])
#     # end

#     # read :get_by_id do
#     #   argument :id, :uuid do
#     #     allow_nil? false
#     #   end

#     #   get? true

#     #   filter expr(id == ^arg(:id))
#     # end
#   end

#   # code_interface do
#   #   define_for HousingApp.Management

#   #   define :list
#   #   define :get_by_id, args: [:id]
#   # end

#   multitenancy do
#     strategy :context
#   end
# end
