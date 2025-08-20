defmodule ExAutomationWeb.ReleaseLive.Show do
  use ExAutomationWeb, :live_view

  alias ExAutomation.Gitlab

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Release")} {@release.id}
        <:subtitle>{gettext("This is a release record from your database.")}</:subtitle>
        <:actions>
          <.button navigate={~p"/releases"}>
            <.icon name="hero-arrow-left" />
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title={gettext("Name")}>{@release.name}</:item>
        <:item title={gettext("Date")}>{@release.date}</:item>
        <:item title={gettext("Description")}>{@release.description}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Gitlab.subscribe_releases()
    end

    {:ok,
     socket
     |> assign(:page_title, gettext("Show Release"))
     |> assign(:release, Gitlab.get_release!(id))}
  end

  @impl true
  def handle_info({type, %ExAutomation.Gitlab.Release{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
