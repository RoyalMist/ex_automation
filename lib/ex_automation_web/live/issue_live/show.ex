defmodule ExAutomationWeb.IssueLive.Show do
  use ExAutomationWeb, :live_view

  alias ExAutomation.Jira

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Issue {@issue.id}
        <:subtitle>This is a issue record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/issues"}>
            <.icon name="hero-arrow-left" />
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Key">{@issue.key}</:item>
        <:item title="Parent key">{@issue.parent_key}</:item>
        <:item title="Summary">{@issue.summary}</:item>
        <:item title="Status">{@issue.status}</:item>
        <:item title="Type">{@issue.type}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Jira.subscribe_issues()
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Issue")
     |> assign(:issue, Jira.get_issue!(id))}
  end

  @impl true
  def handle_info(
        {:updated, %ExAutomation.Jira.Issue{id: id} = issue},
        %{assigns: %{issue: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :issue, issue)}
  end

  def handle_info(
        {:deleted, %ExAutomation.Jira.Issue{id: id}},
        %{assigns: %{issue: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current issue was deleted.")
     |> push_navigate(to: ~p"/issues")}
  end

  def handle_info({type, %ExAutomation.Jira.Issue{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
