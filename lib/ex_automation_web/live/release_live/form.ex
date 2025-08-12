defmodule ExAutomationWeb.ReleaseLive.Form do
  use ExAutomationWeb, :live_view

  alias ExAutomation.Gitlab
  alias ExAutomation.Gitlab.Release

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage release records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="release-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:date]} type="datetime-local" label="Date" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Release</.button>
          <.button navigate={return_path(@current_scope, @return_to, @release)}>Cancel</.button>
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
    release = Gitlab.get_release!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Release")
    |> assign(:release, release)
    |> assign(:form, to_form(Gitlab.change_release(socket.assigns.current_scope, release)))
  end

  defp apply_action(socket, :new, _params) do
    release = %Release{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Release")
    |> assign(:release, release)
    |> assign(:form, to_form(Gitlab.change_release(socket.assigns.current_scope, release)))
  end

  @impl true
  def handle_event("validate", %{"release" => release_params}, socket) do
    changeset =
      Gitlab.change_release(socket.assigns.current_scope, socket.assigns.release, release_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"release" => release_params}, socket) do
    save_release(socket, socket.assigns.live_action, release_params)
  end

  defp save_release(socket, :edit, release_params) do
    case Gitlab.update_release(
           socket.assigns.current_scope,
           socket.assigns.release,
           release_params
         ) do
      {:ok, release} ->
        {:noreply,
         socket
         |> put_flash(:info, "Release updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, release)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_release(socket, :new, release_params) do
    case Gitlab.create_release(socket.assigns.current_scope, release_params) do
      {:ok, release} ->
        {:noreply,
         socket
         |> put_flash(:info, "Release created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, release)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _release), do: ~p"/releases"
  defp return_path(_scope, "show", release), do: ~p"/releases/#{release}"
end
