defmodule ExAutomationWeb.ReportLive.Form do
  use ExAutomationWeb, :live_view

  alias ExAutomation.Reporting
  alias ExAutomation.Reporting.Report

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage report records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="report-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:year]} type="number" label="Year" />

        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Report</.button>
          <.button navigate={return_path(@current_scope, @return_to, @report)}>Cancel</.button>
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
    report = %Report{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Report")
    |> assign(:report, report)
    |> assign(
      :form,
      to_form(Report.create_changeset(%Report{}, %{}, socket.assigns.current_scope))
    )
  end

  @impl true
  def handle_event("validate", %{"report" => report_params}, socket) do
    changeset =
      Report.create_changeset(socket.assigns.report, report_params, socket.assigns.current_scope)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"report" => report_params}, socket) do
    save_report(socket, socket.assigns.live_action, report_params)
  end

  defp save_report(socket, :new, report_params) do
    case Reporting.create_report(socket.assigns.current_scope, report_params) do
      {:ok, report} ->
        {:noreply,
         socket
         |> put_flash(:info, "Report created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, report)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _report), do: ~p"/reports"
  defp return_path(_scope, "show", report), do: ~p"/reports/#{report}"
end
