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
            <button
              type="button"
              phx-click="copy_json"
              class="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm font-medium leading-4 text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
            >
              <.icon name="hero-document-duplicate" class="mr-2 h-4 w-4" /> Copy JSON
            </button>
          </div>
          <div class="relative overflow-x-auto rounded-lg bg-gray-900 p-4 shadow-inner">
            <pre class="font-mono whitespace-pre-wrap text-sm leading-relaxed"><code phx-no-format id="json-content">{format_highlighted_json(@report.entries)}</code></pre>
          </div>
          <p class="mt-2 text-xs text-gray-500">
            {@report.entries |> length()} entries • Pretty formatted JSON
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
     |> assign(:report, Reporting.get_report!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_event("copy_json", _params, socket) do
    # Use plain JSON for copying (without HTML highlighting)
    json_content = format_json(socket.assigns.report.entries)

    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{text: json_content})
     |> put_flash(:info, "JSON copied to clipboard!")}
  end

  defp format_json(data) do
    data
    |> Jason.encode!(pretty: true)
  end

  defp format_highlighted_json(data) do
    data
    |> Jason.encode!(pretty: true)
    |> add_syntax_highlighting()
    |> Phoenix.HTML.raw()
  end

  defp add_syntax_highlighting(json_string) do
    json_string
    # Highlight keys (strings followed by colon)
    |> String.replace(
      ~r/"([^"]+)"\s*:/,
      "<span class=\"text-blue-400\">\"\\1\"</span><span class=\"text-gray-300\">:</span>"
    )
    # Highlight string values (strings not followed by colon)
    |> String.replace(~r/:\s*"([^"]*)"/, ": <span class=\"text-green-400\">\"\\1\"</span>")
    # Highlight numbers
    |> String.replace(~r/:\s*(-?\d+\.?\d*)/, ": <span class=\"text-yellow-400\">\\1</span>")
    # Highlight booleans
    |> String.replace(~r/:\s*(true|false)/, ": <span class=\"text-red-400\">\\1</span>")
    # Highlight null
    |> String.replace(~r/:\s*(null)/, ": <span class=\"text-gray-400\">\\1</span>")
    # Color brackets and braces
    |> String.replace(~r/([{}[\]])/, "<span class=\"text-gray-300\">\\1</span>")
    # Color commas
    |> String.replace(~r/(,)/, "<span class=\"text-gray-300\">\\1</span>")
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
end
