defmodule HousingAppWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  import HousingAppWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:phx_target, :string, default: nil)
  attr(:on_cancel, JS, default: %JS{})
  attr(:on_confirm, JS, default: %JS{})
  attr(:on_confirm_alt, JS, default: %JS{})

  slot(:inner_block, required: true)
  slot(:title)
  slot(:subtitle)
  slot(:confirm)
  slot(:confirm_alt)
  slot(:cancel)

  def custom_modal(assigns) do
    ~H"""
    <div id={@id} phx-mounted={@show && show_modal(@id)} phx-remove={hide_modal(@id)} class="relative z-50 hidden">
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-zinc-50/90 dark:bg-zinc-500/90 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && show_modal(@id)}
              phx-window-keydown={hide_modal(@on_cancel, @id)}
              phx-key="escape"
              phx-click-away={hide_modal(@on_cancel, @id)}
              class="hidden relative rounded-2xl bg-white dark:bg-gray-700 p-14 shadow-lg shadow-zinc-700/10 ring-1 ring-zinc-700/10 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={hide_modal(@on_cancel, @id)}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-80 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5 stroke-current dark:text-white" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <header :if={@title != []}>
                  <h1 id={"#{@id}-title"} class="text-lg font-semibold leading-8 text-zinc-800 dark:text-gray-100">
                    <%= render_slot(@title) %>
                  </h1>
                  <p
                    :if={@subtitle != []}
                    id={"#{@id}-description"}
                    class="mt-2 text-sm leading-6 text-zinc-600 dark:text-white"
                  >
                    <%= render_slot(@subtitle) %>
                  </p>
                </header>
                <div class="p-4 space-y-4">
                  <%= render_slot(@inner_block) %>
                </div>
                <div :if={@confirm != [] or @confirm_alt != [] or @cancel != []} class="ml-6 mb-4 flex items-center gap-5">
                  <.button
                    :for={confirm <- @confirm}
                    id={"#{@id}-confirm"}
                    phx-click={@on_confirm}
                    phx-target={@phx_target}
                    phx-disable-with
                    class="py-2 px-3 dark:text-white"
                  >
                    <%= render_slot(confirm) %>
                  </.button>
                  <.button
                    :for={confirm_alt <- @confirm_alt}
                    id={"#{@id}-confirm-alt"}
                    phx-click={@on_confirm_alt}
                    phx-target={@phx_target}
                    phx-disable-with
                    class="py-2 px-3 dark:text-white"
                  >
                    <%= render_slot(confirm_alt) %>
                  </.button>
                  <.link
                    :for={cancel <- @cancel}
                    phx-click={hide_modal(@on_cancel, @id)}
                    class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700 dark:text-white dark:hover:text-zinc-200"
                  >
                    <%= render_slot(cancel) %>
                  </.link>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title="Success!" flash={@flash} />
      <.flash kind={:error} title="Error!" flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title="We can't find the internet"
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        Hang in there while we get back on track <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"
  attr :class, :string, default: nil
  attr :autowidth, :boolean, default: true, doc: "the autowidth flag"

  attr :rest, :global,
    include:
      ~w(autocomplete name rel action enctype method novalidate target multipart phx-target phx-submit phx-change),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :flex_inputs, doc: "the slot for form flex inputs"
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form
      :let={f}
      for={@for}
      as={@as}
      {@rest}
      class={[
        @autowidth && "max-w-sm mx-auto",
        @class
      ]}
    >
      <%= render_slot(@inner_block, f) %>
      <div :if={Enum.count(@flex_inputs) > 1} class="flex items-start mb-5">
        <div :for={flex_input <- @flex_inputs} class="flex items-center h-5">
          <%= render_slot(flex_input, f) %>
        </div>
      </div>
      <div :for={action <- @actions} class="flex items-center space-x-4">
        <%= render_slot(action, f) %>
      </div>
    </.form>
    """
  end

  slot :inner_block
  attr :form, :any, required: true, doc: "the datastructure for the form"
  attr :json_schema, :map, required: true, doc: "the json schema"
  attr :embed, :boolean, default: false
  attr :add_custom_root, :boolean, default: true
  attr :variables, :map, default: %{}
  attr :prefix, :string, default: ""
  attr :autowidth, :boolean, default: true, doc: "the autowidth flag"
  attr :class, :string, default: nil
  attr :button_text, :string, default: "Submit"
  attr :actor, :any, default: nil
  attr :tenant, :any, default: nil
  attr(:rest, :global, include: ~w(phx-target phx-submit phx-change))

  def json_form(%{embed: true, add_custom_root: false} = assigns) do
    ~H"""
    <%= render_schema(%{
      definitions: HousingApp.Utils.JsonSchema.to_html_form_inputs(@json_schema, @prefix, actor: @actor, tenant: @tenant),
      form: @form,
      variables: @variables
    }) %>
    """
  end

  def json_form(%{embed: true} = assigns) do
    ~H"""
    <%= render_schema(%{
      definitions:
        HousingApp.Utils.JsonSchema.to_html_form_inputs(
          %{
            "properties" => %{
              "data" => Map.merge(%{"type" => "object", "title" => "Custom Fields", "properties" => %{}}, @json_schema)
            }
          },
          @prefix,
          actor: @actor,
          tenant: @tenant
        ),
      variables: @variables,
      form: @form
    }) %>
    """
  end

  def json_form(assigns) do
    ~H"""
    <.simple_form
      for={@form}
      autowidth={@autowidth}
      class={@class}
      phx-change={Map.get(@rest, :"phx-change", "validate")}
      phx-submit={Map.get(@rest, :"phx-submit", "submit")}
      autocomplete="off"
      {@rest}
    >
      <%= render_slot(@inner_block, @form) %>

      <h1
        :if={!is_nil(@json_schema["title"]) && @json_schema["title"] != ""}
        class="mb-4 text-xl font-bold text-gray-900 dark:text-white"
      >
        <%= @json_schema["title"] %>
      </h1>

      <%= render_schema(%{
        definitions: HousingApp.Utils.JsonSchema.to_html_form_inputs(@json_schema, @prefix, actor: @actor, tenant: @tenant),
        variables: @variables,
        form: @form
      }) %>

      <:actions>
        <.button><%= @button_text %></.button>
      </:actions>
    </.simple_form>
    """
  end

  defp render_schema(assigns) do
    ~H"""
    <%= for definition <- @definitions do %>
      <%= case definition.type do %>
        <% "object" -> %>
          <h3
            :if={!is_nil(definition.title) && definition.title != ""}
            class="mb-4 text-base font-bold text-gray-900 dark:text-white"
          >
            <.render_mustache content={definition.title} variables={@variables} />
          </h3>
          <div class="pl-4">
            <%= Phoenix.HTML.Form.inputs_for @form, definition.key, fn fp -> %>
              <%= render_schema(%{definitions: definition.definitions, form: fp, variables: @variables}) %>
            <% end %>
          </div>
        <% _ -> %>
          <.input
            field={@form[definition.key]}
            data-lpignore="true"
            variables={@variables}
            {definition |> Map.delete(:key)}
          />
      <% end %>
    <% end %>
    """
  end

  attr :data, :map, required: true, doc: "the data for viewing"
  attr :json_schema, :map, required: true, doc: "the json schema"

  def json_view(assigns) do
    ~H"""
    <dl>
      <dt
        :if={!is_nil(@json_schema["title"]) && @json_schema["title"] != ""}
        class="mb-2 font-semibold leading-none text-gray-900 dark:text-white"
      >
        <%= @json_schema["title"] %>
      </dt>
      <%= render_json_view(%{definitions: HousingApp.Utils.JsonSchema.to_html_form_inputs(@json_schema), data: @data}) %>
    </dl>
    """
  end

  defp render_json_view(assigns) do
    ~H"""
    <%= for definition <- @definitions do %>
      <%= case definition do %>
        <% %{type: "object"} -> %>
          <dt
            :if={!is_nil(definition.title) && definition.title != ""}
            class="mb-2 font-semibold leading-none text-gray-900 dark:text-white"
          >
            <%= definition.title %>
          </dt>
          <div class="pl-4">
            <%= render_json_view(%{definitions: definition.definitions, data: @data[Atom.to_string(definition.key)]}) %>
          </div>
        <% %{type: "select", multiple: true} -> %>
          <dd class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-300">
            <%= Atom.to_string(definition.key) |> HousingApp.Utils.String.titlize() %>:
            <div class="flex items-center space-x-2">
              <span :for={item <- @data[Atom.to_string(definition.key)]} class="rounded-sm p-2 bg-gray-800 dark:bg-gray-700">
                <%= item %>
              </span>
            </div>
          </dd>
        <% _ -> %>
          <dd class="mb-4 font-light text-gray-500 sm:mb-5 dark:text-gray-400">
            <%= Atom.to_string(definition.key) |> HousingApp.Utils.String.titlize() %>: <%= @data[
              Atom.to_string(definition.key)
            ] %>
          </dd>
      <% end %>
    <% end %>
    """
  end

  attr :content, :string, required: true
  attr :variables, :map, default: %{}

  def render_mustache(%{content: nil} = assigns),
    do: ~H"""

    """

  def render_mustache(assigns) do
    ~H"""
    <%= Phoenix.HTML.raw(Mustache.render(@content, @variables)) %>
    """
  end

  @doc """
  Renders a button.
  https://flowbite.com/docs/components/buttons/

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(%{type: "delete"} = assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "text-red-600 inline-flex items-center hover:text-white border border-red-600 hover:bg-red-600 focus:ring-4 focus:outline-none focus:ring-red-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:border-red-500 dark:text-red-500 dark:hover:text-white dark:hover:bg-red-600 dark:focus:ring-red-900",
        @class
      ]}
      {@rest}
    >
      <svg class="w-5 h-5 mr-1 -ml-1" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
        <path
          fill-rule="evenodd"
          d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z"
          clip-rule="evenodd"
        >
        </path>
      </svg>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def button(%{type: "reset"} = assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "text-red-600 inline-flex items-center hover:text-white border border-red-600 hover:bg-red-600 focus:ring-4 focus:outline-none focus:ring-red-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:border-red-500 dark:text-red-500 dark:hover:text-white dark:hover:bg-red-600 dark:focus:ring-red-900",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75",
        "text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :variables, :map, default: %{}

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio choice search select tel text textarea time url week message json)

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name} class="mb-5">
      <div class="flex items-center">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="w-4 h-4 bg-gray-100 border-gray-300 rounded text-primary-600 focus:ring-primary-500 dark:focus:ring-primary-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
          {@rest}
        />
        <label for={@id} class="ml-2 text-sm font-medium text-gray-900 dark:text-gray-300">
          <.render_mustache content={@label} variables={@variables} />
        </label>
        <.error :for={msg <- @errors}><%= msg %></.error>
      </div>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="mb-5">
      <.label for={@id}><.render_mustache content={@label} variables={@variables} /></.label>
      <div class="relative">
        <select
          id={@id}
          name={@name}
          class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-primary-500 focus:border-primary-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-primary-500 dark:focus:border-primary-500"
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value=""><%= @prompt %></option>
          <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
        </select>
        <%= if @inner_block, do: render_slot(@inner_block) %>
      </div>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "choice"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name} class="mb-5">
      <.label for={@id}><.render_mustache content={@label} variables={@variables} /></.label>
      <div class="relative">
        <ul class="items-center w-full text-sm font-medium text-gray-900 bg-white border border-gray-200 rounded-lg sm:flex dark:bg-gray-700 dark:border-gray-600 dark:text-white">
          <li
            :for={{name, choice} <- @options}
            class="w-full border-b border-gray-200 sm:border-b-0 sm:border-r dark:border-gray-600"
          >
            <div class="flex items-center ps-3">
              <input
                id={@id <> "-" <> choice}
                type="radio"
                value={choice}
                name={@name}
                checked={@checked}
                {@rest}
                class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-700 dark:focus:ring-offset-gray-700 focus:ring-2 dark:bg-gray-600 dark:border-gray-500"
              />
              <label
                for={@id <> "-" <> choice}
                class="w-full py-3 ms-2 text-sm font-medium text-gray-900 dark:text-gray-300"
              >
                <%= name %>
              </label>
            </div>
          </li>
        </ul>

        <%= if @inner_block, do: render_slot(@inner_block) %>
      </div>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="mb-5">
      <.label for={@id}><.render_mustache content={@label} variables={@variables} /></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "block p-2.5 w-full text-sm text-gray-900 bg-gray-50 rounded-lg border border-gray-300 focus:ring-primary-500 focus:border-primary-500 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-primary-500 dark:focus:border-primary-500",
          "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "json"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="mb-5">
      <.label for={@id}><.render_mustache content={@label} variables={@variables} /></.label>

      <div
        phx-hook="JsonEditor"
        phx-update="ignore"
        data-input-id={@name}
        id={"#{@name}_editor"}
        class={[
          "h-96",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
      />

      <input
        type="hidden"
        phx-hook="JsonEditorSource"
        data-editor-id={"#{@name}_editor"}
        value={@value}
        name={@name}
        id={@name}
      />

      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # FUTURE: Do we really want to use Phoenix.HTML.raw? So we can show symbols like "&"
  def input(%{type: "message"} = assigns) do
    ~H"""
    <div class="mb-5">
      <p :if={!is_nil(@label) and @label != ""} class="text-lg text-gray-500 dark:text-gray-400">
        <.render_mustache content={@label} variables={@variables} />
      </p>
      <p :if={not is_nil(@value)} class="text-gray-500 dark:text-gray-400">
        <.render_mustache content={@value} variables={@variables} />
      </p>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="mb-5">
      <.label for={@id}><.render_mustache content={@label} variables={@variables} /></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-primary-600 focus:border-primary-600 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-primary-500 dark:focus:border-primary-500",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="required block mb-2 text-sm font-medium text-gray-900 dark:text-white">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-2 text-sm text-red-600 dark:text-red-500 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :pagination, :boolean, default: false, doc: "the pagination flag"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :button

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="bg-white dark:bg-gray-800 relative shadow-md sm:rounded-lg overflow-hidden">
      <div
        :if={@button != []}
        class="flex flex-col md:flex-row items-center justify-between space-y-3 md:space-y-0 md:space-x-4 p-4"
      >
        <div :if={false} class="w-full md:w-1/2">
          <form class="flex items-center">
            <label for="simple-search" class="sr-only">Quick filter</label>
            <div class="relative w-full">
              <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                <svg
                  aria-hidden="true"
                  class="w-5 h-5 text-gray-500 dark:text-gray-400"
                  fill="currentColor"
                  viewbox="0 0 20 20"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    fill-rule="evenodd"
                    d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <input
                type="text"
                id="simple-search"
                class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-primary-500 focus:border-primary-500 block w-full pl-10 p-2 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-primary-500 dark:focus:border-primary-500"
                placeholder="Quick filter"
                required=""
              />
            </div>
          </form>
        </div>
        <div class="w-full md:w-auto flex flex-col md:flex-row space-y-2 md:space-y-0 items-stretch md:items-center justify-end md:space-x-3 flex-shrink-0">
          <button
            :for={button <- @button}
            type="button"
            class="flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-4 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
          >
            <%= render_slot(button) %>
          </button>
        </div>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-sm text-left text-gray-500 dark:text-gray-400">
          <thead class="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
            <tr>
              <th :for={col <- @col} scope="col" class="px-4 py-3"><%= col[:label] %></th>
              <th :if={@action != []} scope="col" class="px-4 py-3">
                <span class="sr-only"><%= gettext("Actions") %></span>
              </th>
            </tr>
          </thead>
          <tbody id={@id} phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}>
            <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="border-b dark:border-gray-700">
              <td
                :for={{col, i} <- Enum.with_index(@col)}
                phx-click={@row_click && @row_click.(row)}
                class={[
                  "px-4 py-3",
                  @row_click && "hover:cursor-pointer",
                  i == 0 && "font-medium text-gray-900 whitespace-nowrap dark:text-white"
                ]}
              >
                <%= render_slot(col, @row_item.(row)) %>
              </td>
              <td :if={@action != []} class="px-4 py-3 flex items-center justify-end">
                <button
                  id={@row_id && "#{@row_id.(row)}-dropdown-button"}
                  data-dropdown-toggle={@row_id && "#{@row_id.(row)}-dropdown"}
                  class="inline-flex items-center p-0.5 text-sm font-medium text-center text-gray-500 hover:text-gray-800 rounded-lg focus:outline-none dark:text-gray-400 dark:hover:text-gray-100"
                  type="button"
                >
                  <svg
                    class="w-5 h-5"
                    aria-hidden="true"
                    fill="currentColor"
                    viewbox="0 0 20 20"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z" />
                  </svg>
                </button>
                <div
                  id={@row_id && "#{@row_id.(row)}-dropdown"}
                  class="hidden z-10 w-44 bg-white rounded divide-y divide-gray-100 shadow dark:bg-gray-700 dark:divide-gray-600"
                >
                  <ul
                    class="py-1 text-sm text-gray-700 dark:text-gray-200"
                    aria-labelledby={@row_id && "#{@row_id.(row)}-dropdown-button"}
                  >
                    <li :for={action <- @action}>
                      <%= render_slot(action, @row_item.(row)) %>
                    </li>
                  </ul>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <nav
        :if={@pagination}
        class="flex flex-col md:flex-row justify-between items-start md:items-center space-y-3 md:space-y-0 p-4"
        aria-label="Table navigation"
      >
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">
          Showing <span class="font-semibold text-gray-900 dark:text-white">1-10</span>
          of <span class="font-semibold text-gray-900 dark:text-white">1000</span>
        </span>
        <ul class="inline-flex items-stretch -space-x-px">
          <li>
            <a
              href="#"
              class="flex items-center justify-center h-full py-1.5 px-3 ml-0 text-gray-500 bg-white rounded-l-lg border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            >
              <span class="sr-only">Previous</span>
              <svg
                class="w-5 h-5"
                aria-hidden="true"
                fill="currentColor"
                viewbox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  fill-rule="evenodd"
                  d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z"
                  clip-rule="evenodd"
                />
              </svg>
            </a>
          </li>
          <li>
            <a
              href="#"
              class="flex items-center justify-center text-sm py-2 px-3 leading-tight text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            >
              1
            </a>
          </li>
          <li>
            <a
              href="#"
              class="flex items-center justify-center text-sm py-2 px-3 leading-tight text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            >
              2
            </a>
          </li>
          <li>
            <a
              href="#"
              aria-current="page"
              class="flex items-center justify-center text-sm z-10 py-2 px-3 leading-tight text-primary-600 bg-primary-50 border border-primary-300 hover:bg-primary-100 hover:text-primary-700 dark:border-gray-700 dark:bg-gray-700 dark:text-white"
            >
              3
            </a>
          </li>
          <li>
            <a
              href="#"
              class="flex items-center justify-center text-sm py-2 px-3 leading-tight text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            >
              ...
            </a>
          </li>
          <li>
            <a
              href="#"
              class="flex items-center justify-center text-sm py-2 px-3 leading-tight text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            >
              100
            </a>
          </li>
          <li>
            <a
              href="#"
              class="flex items-center justify-center h-full py-1.5 px-3 leading-tight text-gray-500 bg-white rounded-r-lg border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            >
              <span class="sr-only">Next</span>
              <svg
                class="w-5 h-5"
                aria-hidden="true"
                fill="currentColor"
                viewbox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  fill-rule="evenodd"
                  d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                  clip-rule="evenodd"
                />
              </svg>
            </a>
          </li>
        </ul>
      </nav>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link navigate={@navigate} class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700">
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Renders a gravatar icon
  """

  attr(:email, :string, default: nil)
  attr(:alternate, :string, default: nil)
  attr(:alt, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def gravatar(assigns) do
    src =
      cond do
        !is_nil(assigns.email) ->
          hash =
            assigns.email
            |> String.trim()
            |> String.downcase()
            |> :erlang.md5()
            |> Base.encode16(case: :lower)

          "https://www.gravatar.com/avatar/#{hash}?s=150&d=#{default_gravatar(assigns.alternate)}"

        !is_nil(assigns.alternate) ->
          assigns.alternate

        true ->
          nil
      end

    assigns =
      assign(assigns, src: src)

    ~H"""
    <img
      :if={@src}
      class={[
        "h-8 w-8 rounded-full",
        @class
      ]}
      src={@src}
      title={@alt}
      {@rest}
    />
    """
  end

  defp default_gravatar(""), do: "identicon"
  defp default_gravatar(avatar) when is_nil(avatar), do: "identicon"

  defp default_gravatar(avatar) do
    URI.encode(avatar)
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(HousingAppWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(HousingAppWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
