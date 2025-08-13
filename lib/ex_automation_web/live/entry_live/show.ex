defmodule ExAutomationWeb.EntryLive.Show do
  use ExAutomationWeb, :live_view

  alias ExAutomation.Reporting

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Entry {@entry.id}
        <:subtitle>This is a entry record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/entries"}>
            <.icon name="hero-arrow-left" />
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Release name">{@entry.release_name}</:item>
        <:item title="Release date">{@entry.release_date}</:item>
        <:item title="Issue key">{@entry.issue_key}</:item>
        <:item title="Issue summary">{@entry.issue_summary}</:item>
        <:item title="Issue type">{@entry.issue_type}</:item>
        <:item title="Issue status">{@entry.issue_status}</:item>
        <:item title="Initiative key">{@entry.initiative_key}</:item>
        <:item title="Initiative summary">{@entry.initiative_summary}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Reporting.subscribe_entries(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Entry")
     |> assign(:entry, Reporting.get_entry!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info({type, %ExAutomation.Reporting.Entry{}}, socket)
      when type in [:created] do
    {:noreply, socket}
  end
end
