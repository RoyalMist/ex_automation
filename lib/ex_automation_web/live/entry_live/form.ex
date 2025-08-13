defmodule ExAutomationWeb.EntryLive.Form do
  use ExAutomationWeb, :live_view

  alias ExAutomation.Reporting
  alias ExAutomation.Reporting.Entry

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage entry records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="entry-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:release_name]} type="text" label="Release name" />
        <.input field={@form[:release_date]} type="datetime-local" label="Release date" />
        <.input field={@form[:issue_key]} type="text" label="Issue key" />
        <.input field={@form[:issue_summary]} type="text" label="Issue summary" />
        <.input field={@form[:issue_type]} type="text" label="Issue type" />
        <.input field={@form[:issue_status]} type="text" label="Issue status" />
        <.input field={@form[:initiative_key]} type="text" label="Initiative key" />
        <.input field={@form[:initiative_summary]} type="text" label="Initiative summary" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Entry</.button>
          <.button navigate={return_path(@current_scope, @return_to, @entry)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :new, _params) do
    entry = %Entry{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Entry")
    |> assign(:entry, entry)
    |> assign(:form, to_form(Entry.changeset(%Entry{}, %{}, socket.assigns.current_scope)))
  end

  @impl true
  def handle_event("validate", %{"entry" => entry_params}, socket) do
    changeset =
      Entry.changeset(socket.assigns.entry, entry_params, socket.assigns.current_scope)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"entry" => entry_params}, socket) do
    save_entry(socket, socket.assigns.live_action, entry_params)
  end

  defp save_entry(socket, :new, entry_params) do
    case Reporting.create_entry(socket.assigns.current_scope, entry_params) do
      {:ok, entry} ->
        {:noreply,
         socket
         |> put_flash(:info, "Entry created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, entry)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _entry), do: ~p"/entries"
  defp return_path(_scope, "show", entry), do: ~p"/entries/#{entry}"
end
