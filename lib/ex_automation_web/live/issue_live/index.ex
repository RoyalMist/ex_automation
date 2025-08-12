defmodule ExAutomationWeb.IssueLive.Index do
  use ExAutomationWeb, :live_view

  alias ExAutomation.Jira

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Issues
        <:actions>
          <.button variant="primary" navigate={~p"/issues/new"}>
            <.icon name="hero-plus" /> New Issue
          </.button>
        </:actions>
      </.header>

      <.table
        id="issues"
        rows={@streams.issues}
        row_click={fn {_id, issue} -> JS.navigate(~p"/issues/#{issue}") end}
      >
        <:col :let={{_id, issue}} label="Key">{issue.key}</:col>
        <:col :let={{_id, issue}} label="Parent key">{issue.parent_key}</:col>
        <:col :let={{_id, issue}} label="Summary">{issue.summary}</:col>
        <:col :let={{_id, issue}} label="Status">{issue.status}</:col>
        <:col :let={{_id, issue}} label="Type">{issue.type}</:col>
        <:action :let={{_id, issue}}>
          <div class="sr-only">
            <.link navigate={~p"/issues/#{issue}"}>Show</.link>
          </div>
          <.link navigate={~p"/issues/#{issue}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, issue}}>
          <.link
            phx-click={JS.push("delete", value: %{id: issue.id}) |> hide("##{id}")}
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
      Jira.subscribe_issues(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Issues")
     |> stream(:issues, Jira.list_issues(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    issue = Jira.get_issue!(socket.assigns.current_scope, id)
    {:ok, _} = Jira.delete_issue(socket.assigns.current_scope, issue)

    {:noreply, stream_delete(socket, :issues, issue)}
  end

  @impl true
  def handle_info({type, %ExAutomation.Jira.Issue{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :issues, Jira.list_issues(socket.assigns.current_scope), reset: true)}
  end
end
