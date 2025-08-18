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
        <:item title="Complete">{if @report.complete, do: "Yes", else: "No"}</:item>
      </.list>
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
