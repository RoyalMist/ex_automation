defmodule ExAutomationWeb.IssueLive.Form do
  use ExAutomationWeb, :live_view

  alias ExAutomation.Jira
  alias ExAutomation.Jira.Issue

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage issue records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="issue-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:key]} type="text" label="Key" />
        <.input field={@form[:parent_key]} type="text" label="Parent key" />
        <.input field={@form[:summary]} type="textarea" label="Summary" />
        <.input field={@form[:status]} type="text" label="Status" />
        <.input field={@form[:type]} type="text" label="Type" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Issue</.button>
          <.button navigate={return_path(@current_scope, @return_to, @issue)}>Cancel</.button>
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

  defp apply_action(socket, :edit, %{"id" => id}) do
    issue = Jira.get_issue!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Issue")
    |> assign(:issue, issue)
    |> assign(:form, to_form(Jira.change_issue(socket.assigns.current_scope, issue)))
  end

  defp apply_action(socket, :new, _params) do
    issue = %Issue{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Issue")
    |> assign(:issue, issue)
    |> assign(:form, to_form(Jira.change_issue(socket.assigns.current_scope, issue)))
  end

  @impl true
  def handle_event("validate", %{"issue" => issue_params}, socket) do
    changeset = Jira.change_issue(socket.assigns.current_scope, socket.assigns.issue, issue_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"issue" => issue_params}, socket) do
    save_issue(socket, socket.assigns.live_action, issue_params)
  end

  defp save_issue(socket, :edit, issue_params) do
    case Jira.update_issue(socket.assigns.current_scope, socket.assigns.issue, issue_params) do
      {:ok, issue} ->
        {:noreply,
         socket
         |> put_flash(:info, "Issue updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, issue)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_issue(socket, :new, issue_params) do
    case Jira.create_issue(socket.assigns.current_scope, issue_params) do
      {:ok, issue} ->
        {:noreply,
         socket
         |> put_flash(:info, "Issue created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, issue)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _issue), do: ~p"/issues"
  defp return_path(_scope, "show", issue), do: ~p"/issues/#{issue}"
end
