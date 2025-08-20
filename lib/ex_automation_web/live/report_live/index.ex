defmodule ExAutomationWeb.ReportLive.Index do
  use ExAutomationWeb, :live_view
  alias ExAutomation.Reporting

  @impl true
  def render(assigns) do
    cell_classes = fn report ->
      base_classes = if !report.completed, do: "opacity-60", else: ""

      cursor_classes =
        if report.completed, do: "cursor-pointer hover:bg-base-200", else: "cursor-not-allowed"

      [base_classes, cursor_classes]
    end

    assigns = assign(assigns, :cell_classes, cell_classes)

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
        row_click={
          fn {_id, report} ->
            if report.completed, do: JS.navigate(~p"/reports/#{report}"), else: %JS{}
          end
        }
      >
        <:col :let={{_id, report}} label="Name">
          <span
            data-completed={to_string(report.completed)}
            class={@cell_classes.(report)}
          >
            {report.name}
          </span>
        </:col>
        <:col :let={{_id, report}} label="Year">
          <span
            data-completed={to_string(report.completed)}
            class={@cell_classes.(report)}
          >
            {report.year}
          </span>
        </:col>
        <:col :let={{_id, report}} label="Completed">
          <span
            data-completed={to_string(report.completed)}
            class={@cell_classes.(report)}
          >
            {if report.completed, do: "✓", else: "✗"}
          </span>
        </:col>
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
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(socket, :reports, Reporting.list_reports(socket.assigns.current_scope), reset: true)}
  end
end
