defmodule ExAutomationWeb.EntryLive.Index do
  use ExAutomationWeb, :live_view

  alias ExAutomation.Reporting

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Entries
        <:actions>
          <.button variant="primary" navigate={~p"/entries/new"}>
            <.icon name="hero-plus" /> New Entry
          </.button>
        </:actions>
      </.header>

      <.table
        id="entries"
        rows={@streams.entries}
        row_click={fn {_id, entry} -> JS.navigate(~p"/entries/#{entry}") end}
      >
        <:col :let={{_id, entry}} label="Release name">{entry.release_name}</:col>
        <:col :let={{_id, entry}} label="Release date">{entry.release_date}</:col>
        <:col :let={{_id, entry}} label="Issue key">{entry.issue_key}</:col>
        <:col :let={{_id, entry}} label="Issue summary">{entry.issue_summary}</:col>
        <:col :let={{_id, entry}} label="Issue type">{entry.issue_type}</:col>
        <:col :let={{_id, entry}} label="Issue status">{entry.issue_status}</:col>
        <:col :let={{_id, entry}} label="Initiative key">{entry.initiative_key}</:col>
        <:col :let={{_id, entry}} label="Initiative summary">{entry.initiative_summary}</:col>
        <:action :let={{_id, entry}}>
          <div class="sr-only">
            <.link navigate={~p"/entries/#{entry}"}>Show</.link>
          </div>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Reporting.subscribe_entries(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Entries")
     |> stream(:entries, Reporting.list_entries(socket.assigns.current_scope))}
  end

  @impl true
  def handle_info({type, %ExAutomation.Reporting.Entry{}}, socket)
      when type in [:created] do
    {:noreply,
     stream(socket, :entries, Reporting.list_entries(socket.assigns.current_scope), reset: true)}
  end
end
