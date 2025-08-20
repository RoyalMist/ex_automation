defmodule ExAutomationWeb.IssueLive.Index do
  use ExAutomationWeb, :live_view

  alias ExAutomation.Jira

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Listing Issues")}
        <:actions>
          <.button variant="primary" navigate={~p"/issues/new"}>
            <.icon name="hero-plus" /> {gettext("New Issue")}
          </.button>
        </:actions>
      </.header>

      <.table
        id="issues"
        rows={@streams.issues}
        row_click={fn {_id, issue} -> JS.navigate(~p"/issues/#{issue}") end}
      >
        <:col :let={{_id, issue}} label={gettext("Key")}>{issue.key}</:col>
        <:col :let={{_id, issue}} label={gettext("Parent")}>
          {if issue.parent_id, do: gettext("Child"), else: gettext("Root")}
        </:col>
        <:col :let={{_id, issue}} label={gettext("Summary")}>{issue.summary}</:col>
        <:col :let={{_id, issue}} label={gettext("Status")}>{issue.status}</:col>
        <:col :let={{_id, issue}} label={gettext("Type")}>{issue.type}</:col>
        <:action :let={{_id, issue}}>
          <div class="sr-only">
            <.link navigate={~p"/issues/#{issue}"}>{gettext("Show")}</.link>
          </div>
        </:action>
        <:action :let={{id, issue}}>
          <.link
            phx-click={JS.push("delete", value: %{id: issue.id}) |> hide("##{id}")}
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
      Jira.subscribe_issues()
    end

    {:ok,
     socket
     |> assign(:page_title, gettext("Listing Issues"))
     |> stream(:issues, Jira.list_issues())}
  end

  @impl true
  def handle_info({type, %ExAutomation.Jira.Issue{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :issues, Jira.list_issues(), reset: true)}
  end
end
