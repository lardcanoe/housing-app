defmodule HousingAppWeb.Live.Accounting.Products.Index do
  @moduledoc false

  use HousingAppWeb, {:live_view, layout: {HousingAppWeb.Layouts, :dashboard}}

  def render(%{live_action: :index} = assigns) do
    ~H"""
    <h1 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Products</h1>

    <.table id="products" rows={@products} pagination={false} row_id={fn row -> "products-row-#{row.id}" end}>
      <:button>
        <svg
          class="h-3.5 w-3.5 mr-2"
          fill="currentColor"
          viewbox="0 0 20 20"
          xmlns="http://www.w3.org/2000/svg"
          aria-hidden="true"
        >
          <path
            clip-rule="evenodd"
            fill-rule="evenodd"
            d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
          />
        </svg>
        <.link navigate={~p"/accounting/products/new"}>
          Add product
        </.link>
      </:button>
      <:col :let={product} label="name">
        <%= product.name %>
      </:col>
      <:col :let={product} label="description">
        <%= product.description %>
      </:col>
      <:col :let={product} label="rate">
        <%= product.rate %>
      </:col>
      <:action :let={product}>
        <.link
          navigate={~p"/accounting/products/#{product.id}/edit"}
          class="block py-2 px-4 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
        >
          Edit
        </.link>
      </:action>
    </.table>
    """
  end

  def mount(_params, _session, socket) do
    case fetch_products(socket) do
      {:ok, products} ->
        {:ok, assign(socket, products: products, sidebar: :accounting, page_title: "Products")}

      _ ->
        {:ok,
         socket
         |> assign(products: [], sidebar: :accounting, page_title: "Products")
         |> put_flash(:error, "Error loading products.")}
    end
  end

  defp fetch_products(socket) do
    %{current_user_tenant: current_user_tenant, current_tenant: tenant} = socket.assigns

    case HousingApp.Accounting.Product.list(actor: current_user_tenant, tenant: tenant) do
      {:ok, products} -> {:ok, products}
      _ -> {:error, []}
    end
  end
end
