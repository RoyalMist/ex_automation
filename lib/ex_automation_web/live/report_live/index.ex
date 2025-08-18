defmodule ExAutomationWeb.ReportLive.Index do
  use ExAutomationWeb, :live_view
  alias ExAutomation.Reporting

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Reports
        <:actions>
          <.button variant="primary" navigate={~p"/reports/new"}>
            <.icon name="hero-plus" /> New Report
          </.button>
        </:actions>
      </.header>

      <.table
        id="reports"
        rows={@streams.reports}
        row_click={fn {_id, report} -> JS.navigate(~p"/reports/#{report}") end}
      >
        <:col :let={{_id, report}} label="Name">{report.name}</:col>
        <:col :let={{_id, report}} label="Year">{report.year}</:col>
        <:col :let={{_id, report}} label="Complete">{if report.complete, do: "✓", else: "✗"}</:col>
        <:action :let={{_id, report}}>
          <div class="sr-only">
            <.link navigate={~p"/reports/#{report}"}>Show</.link>
          </div>
        </:action>
        <:action :let={{id, report}}>
          <.link
            phx-click={JS.push("delete", value: %{id: report.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Reporting.subscribe_reports(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Reports")
     |> stream(:reports, Reporting.list_reports(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    report = Reporting.get_report!(socket.assigns.current_scope, id)
    {:ok, _} = Reporting.delete_report(socket.assigns.current_scope, report)
    {:noreply, stream_delete(socket, :reports, report)}
  end

  @impl true
  def handle_info({type, %ExAutomation.Reporting.Report{}}, socket)
      when type in [:created, :deleted] do
    {:noreply,
     stream(socket, :reports, Reporting.list_reports(socket.assigns.current_scope), reset: true)}
  end
end
