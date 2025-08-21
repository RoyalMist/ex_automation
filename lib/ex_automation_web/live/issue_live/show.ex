defmodule ExAutomationWeb.IssueLive.Show do
  use ExAutomationWeb, :live_view

  alias ExAutomation.Jira

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Issue")} {@issue.id}
        <:subtitle>{gettext("This is a issue record from your database.")}</:subtitle>
        <:actions>
          <.button navigate={~p"/issues"}>
            <.icon name="hero-arrow-left" />
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title={gettext("Key")}>{@issue.key}</:item>
        <:item title={gettext("Parent")}>
          {if @issue.parent_key, do: @issue.parent_key, else: gettext("Root Issue")}
        </:item>
        <:item title={gettext("Summary")}>{@issue.summary}</:item>
        <:item title={gettext("Status")}>{@issue.status}</:item>
        <:item title={gettext("Type")}>{@issue.type}</:item>
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
     |> assign(:page_title, gettext("Show Issue"))
     |> assign(:issue, Jira.get_issue!(id))}
  end

  @impl true
  def handle_info({type, %ExAutomation.Jira.Issue{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
