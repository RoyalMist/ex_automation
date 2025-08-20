defmodule ExAutomationWeb.ReportLive.Show do
  use ExAutomationWeb, :live_view
  alias ExAutomation.Reporting

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Report {@report.id}
        <:subtitle>This is a report record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/reports"}>
            <.icon name="hero-arrow-left" />
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@report.name}</:item>
        <:item title="Year">{@report.year}</:item>
        <:item title="Completed">{if @report.completed, do: "Yes", else: "No"}</:item>
        <:item title="Entries Count">{length(@report.entries)}</:item>
        <:item title="Created">
          {Calendar.strftime(@report.inserted_at, "%B %d, %Y at %I:%M %p")}
        </:item>
        <:item title="Last Updated">
          {Calendar.strftime(@report.updated_at, "%B %d, %Y at %I:%M %p")}
        </:item>
      </.list>

      <%= if @report.entries != [] do %>
        <div class="mt-8">
          <div class="mb-4 flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900">Report Data</h3>
            <div class="flex gap-2">
              <button
                type="button"
                phx-click="toggle_all_json"
                class="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm font-medium leading-4 text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
              >
                <.icon name="hero-eye" class="mr-2 h-4 w-4" />
                {if @all_expanded, do: "Collapse All", else: "Expand All"}
              </button>
              <button
                type="button"
                phx-click="copy_json"
                class="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm font-medium leading-4 text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
              >
                <.icon name="hero-document-duplicate" class="mr-2 h-4 w-4" /> Copy JSON
              </button>
            </div>
          </div>
          <div class="bg-base-300 relative overflow-x-auto rounded-lg p-4 shadow-inner">
            <div class="font-mono text-base-content text-sm leading-6" id="json-viewer">
              <.render_foldable_json
                data={@report.entries}
                expanded_nodes={@expanded_nodes}
                all_expanded={@all_expanded}
                path="root"
              />
            </div>
          </div>
          <p class="mt-2 text-xs text-gray-500">
            {@report.entries |> length()} entries • Foldable JSON viewer
          </p>
        </div>
      <% else %>
        <div class="mt-8">
          <h3 class="mb-4 text-lg font-semibold text-gray-900">Report Data</h3>
          <div class="rounded-lg border-2 border-dashed border-gray-300 bg-gray-50 p-6 text-center">
            <.icon name="hero-document-text" class="mx-auto h-12 w-12 text-gray-400" />
            <h4 class="mt-4 text-sm font-medium text-gray-900">No entries available yet</h4>
            <p class="mt-2 text-sm text-gray-500">
              Report may still be processing. Entries will appear here once the job completes.
            </p>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Reporting.subscribe_reports(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Report")
     |> assign(:report, Reporting.get_report!(socket.assigns.current_scope, id))
     |> assign(:expanded_nodes, MapSet.new())
     |> assign(:all_expanded, false)}
  end

  @impl true
  def handle_event("copy_json", _params, socket) do
    json_content = format_json(socket.assigns.report.entries)

    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{text: json_content})
     |> put_flash(:info, "JSON copied to clipboard!")}
  end

  @impl true
  def handle_event("toggle_all_json", _params, socket) do
    new_all_expanded = !socket.assigns.all_expanded

    {:noreply,
     socket
     |> assign(:all_expanded, new_all_expanded)
     |> assign(:expanded_nodes, if(new_all_expanded, do: MapSet.new(), else: MapSet.new()))}
  end

  @impl true
  def handle_event("toggle_json_node", %{"path" => path}, socket) do
    expanded_nodes = socket.assigns.expanded_nodes

    updated_nodes =
      if MapSet.member?(expanded_nodes, path) do
        MapSet.delete(expanded_nodes, path)
      else
        MapSet.put(expanded_nodes, path)
      end

    {:noreply, assign(socket, :expanded_nodes, updated_nodes)}
  end

  defp format_json(data) do
    data
    |> Jason.encode!(pretty: true)
  end

  @impl true
  def handle_info(
        {:deleted, %ExAutomation.Reporting.Report{id: id}},
        %{assigns: %{report: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current report was deleted.")
     |> push_navigate(to: ~p"/reports")}
  end

  def handle_info({type, %ExAutomation.Reporting.Report{}}, socket)
      when type in [:created, :deleted] do
    {:noreply, socket}
  end

  # Component for rendering foldable JSON
  defp render_foldable_json(assigns) do
    ~H"""
    <%= case @data do %>
      <% data when is_list(data) -> %>
        <.render_json_array
          data={data}
          expanded_nodes={@expanded_nodes}
          all_expanded={@all_expanded}
          path={@path}
        />
      <% data when is_map(data) -> %>
        <.render_json_object
          data={data}
          expanded_nodes={@expanded_nodes}
          all_expanded={@all_expanded}
          path={@path}
        />
      <% data -> %>
        <.render_json_primitive data={data} />
    <% end %>
    """
  end

  defp render_json_array(assigns) do
    is_expanded = assigns.all_expanded or MapSet.member?(assigns.expanded_nodes, assigns.path)
    assigns = assign(assigns, :is_expanded, is_expanded)

    ~H"""
    <span class="text-base-content/70 font-bold">[</span>
    <%= if @is_expanded do %>
      <%= if Enum.empty?(@data) do %>
        <span class="text-base-content/70 font-bold">]</span>
      <% else %>
        <button
          type="button"
          phx-click="toggle_json_node"
          phx-value-path={@path}
          class="text-info mx-1 ml-1 rounded px-1 py-0.5 text-xs transition-all duration-200 hover:bg-info/10 hover:text-info-focus"
        >
          [-]
        </button>
        <div class="border-base-content/20 ml-2 border-l pl-3">
          <%= for {item, index} <- Enum.with_index(@data) do %>
            <div class="flex">
              <.render_foldable_json
                data={item}
                expanded_nodes={@expanded_nodes}
                all_expanded={@all_expanded}
                path={"#{@path}[#{index}]"}
              />
              <%= if index < length(@data) - 1 do %>
                <span class="text-base-content/70 font-bold">,</span>
              <% end %>
            </div>
          <% end %>
        </div>
        <span class="text-base-content/70 font-bold">]</span>
      <% end %>
    <% else %>
      <button
        type="button"
        phx-click="toggle_json_node"
        phx-value-path={@path}
        class="text-info mx-1 ml-1 rounded px-1 py-0.5 text-xs transition-all duration-200 hover:bg-info/10 hover:text-info-focus"
      >
        [+]
      </button>
      <span class="text-base-content/60 italic">... {length(@data)} items</span>
      <span class="text-base-content/70 font-bold">]</span>
    <% end %>
    """
  end

  defp render_json_object(assigns) do
    is_expanded = assigns.all_expanded or MapSet.member?(assigns.expanded_nodes, assigns.path)
    assigns = assign(assigns, :is_expanded, is_expanded)

    ~H"""
    <span class="text-base-content/70 font-bold">&lbrace;</span>
    <%= if @is_expanded do %>
      <%= if Enum.empty?(@data) do %>
        <span class="text-base-content/70 font-bold">&rbrace;</span>
      <% else %>
        <button
          type="button"
          phx-click="toggle_json_node"
          phx-value-path={@path}
          class="text-info mx-1 ml-1 rounded px-1 py-0.5 text-xs transition-all duration-200 hover:bg-info/10 hover:text-info-focus"
        >
          [-]
        </button>
        <div class="border-base-content/20 ml-2 border-l pl-3">
          <%= for {{key, value}, index} <- Enum.with_index(@data) do %>
            <div class="flex">
              <span class="text-info font-medium">"{key}"</span>
              <span class="text-base-content/70 font-bold">: </span>
              <.render_foldable_json
                data={value}
                expanded_nodes={@expanded_nodes}
                all_expanded={@all_expanded}
                path={"#{@path}.#{key}"}
              />
              <%= if index < Enum.count(@data) - 1 do %>
                <span class="text-base-content/70 font-bold">,</span>
              <% end %>
            </div>
          <% end %>
        </div>
        <span class="text-base-content/70 font-bold">&rbrace;</span>
      <% end %>
    <% else %>
      <button
        type="button"
        phx-click="toggle_json_node"
        phx-value-path={@path}
        class="text-info mx-1 ml-1 rounded px-1 py-0.5 text-xs transition-all duration-200 hover:bg-info/10 hover:text-info-focus"
      >
        [+]
      </button>
      <span class="text-base-content/60 italic">... {Enum.count(@data)} keys</span>
      <span class="text-base-content/70 font-bold">&rbrace;</span>
    <% end %>
    """
  end

  defp render_json_primitive(assigns) do
    ~H"""
    <%= case @data do %>
      <% data when is_binary(data) -> %>
        <span class="text-success">"{data}"</span>
      <% data when is_number(data) -> %>
        <span class="text-warning">{data}</span>
      <% data when is_boolean(data) -> %>
        <span class="text-error font-medium">{data}</span>
      <% nil -> %>
        <span class="text-base-content/60 italic">null</span>
      <% data -> %>
        <span class="text-purple-400">{inspect(data)}</span>
    <% end %>
    """
  end
end
