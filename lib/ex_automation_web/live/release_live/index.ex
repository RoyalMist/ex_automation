defmodule ExAutomationWeb.ReleaseLive.Index do
  use ExAutomationWeb, :live_view

  alias ExAutomation.Gitlab

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Listing Releases")}
        <:actions>
          <.button variant="primary" navigate={~p"/releases/new"}>
            <.icon name="hero-plus" /> {gettext("New Release")}
          </.button>
        </:actions>
      </.header>

      <.table
        id="releases"
        rows={@streams.releases}
        row_click={fn {_id, release} -> JS.navigate(~p"/releases/#{release}") end}
      >
        <:col :let={{_id, release}} label={gettext("Name")}>{release.name}</:col>
        <:col :let={{_id, release}} label={gettext("Date")}>{release.date}</:col>
        <:col :let={{_id, release}} label={gettext("Description")}>{release.description}</:col>
        <:action :let={{_id, release}}>
          <div class="sr-only">
            <.link navigate={~p"/releases/#{release}"}>{gettext("Show")}</.link>
          </div>
        </:action>
        <:action :let={{id, release}}>
          <.link
            phx-click={JS.push("delete", value: %{id: release.id}) |> hide("##{id}")}
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
      Gitlab.subscribe_releases()
    end

    {:ok,
     socket
     |> assign(:page_title, gettext("Listing Releases"))
     |> stream(:releases, Gitlab.list_releases())}
  end

  @impl true
  def handle_info({type, %ExAutomation.Gitlab.Release{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :releases, Gitlab.list_releases(), reset: true)}
  end
end
