defmodule ExAutomationWeb.ReportLive.Index do
  use ExAutomationWeb, :live_view
  alias ExAutomation.Reporting

  @impl true
  def render(assigns) do
    cell_classes = fn report ->
      base_classes = if report.completed, do: "", else: "opacity-60"

      cursor_classes =
        if report.completed, do: "cursor-pointer hover:bg-base-200", else: "cursor-not-allowed"

      [base_classes, cursor_classes]
    end

    assigns = assign(assigns, :cell_classes, cell_classes)

    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Listing Reports")}
        <:actions>
          <.button variant="primary" navigate={~p"/reports/new"}>
            <.icon name="hero-plus" /> {gettext("New Report")}
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
        <:col :let={{_id, report}} label={gettext("Name")}>
          <span
            data-completed={to_string(report.completed)}
            class={@cell_classes.(report)}
          >
            {report.name}
          </span>
        </:col>
        <:col :let={{_id, report}} label={gettext("Year")}>
          <span
            data-completed={to_string(report.completed)}
            class={@cell_classes.(report)}
          >
            {report.year}
          </span>
        </:col>
        <:col :let={{_id, report}} label={gettext("Completed")}>
          <span
            data-completed={to_string(report.completed)}
            class={@cell_classes.(report)}
          >
            <%= if report.completed do %>
              <.icon name="hero-check" class="h-5 w-5 text-green-600" />
            <% else %>
              <.icon name="hero-x-mark" class="h-5 w-5 text-red-600" />
            <% end %>
          </span>
        </:col>
        <:action :let={{_id, report}}>
          <div class="sr-only">
            <.link navigate={~p"/reports/#{report}"}>{gettext("Show")}</.link>
          </div>
        </:action>
        <:action :let={{id, report}}>
          <.link
            phx-click={JS.push("delete", value: %{id: report.id}) |> hide("##{id}")}
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
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
     |> assign(:page_title, gettext("Listing Reports"))
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
