defmodule ExAutomation.Reporting do
  @moduledoc """
  The Reporting context.
  """

  import Ecto.Query, warn: false
  alias ExAutomation.Repo
  alias ExAutomation.Reporting.Report
  alias ExAutomation.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any report changes.

  The broadcasted messages match the pattern:

    * {:created, %Report{}}
    * {:deleted, %Report{}}

  """
  def subscribe_reports(%Scope{} = scope) do
    key = scope.user.id
    Phoenix.PubSub.subscribe(ExAutomation.PubSub, "user:#{key}:reports")
  end

  defp broadcast_reports(%Scope{} = scope, message) do
    key = scope.user.id
    Phoenix.PubSub.broadcast(ExAutomation.PubSub, "user:#{key}:reports", message)
  end

  @doc """
  Returns the list of reports.

  ## Examples

      iex> list_reports(scope)
      [%Report{}, ...]

  """
  def list_reports(%Scope{} = scope) do
    Repo.all_by(Report, user_id: scope.user.id)
  end

  @doc """
  Gets a single report.

  Raises `Ecto.NoResultsError` if the Report does not exist.

  ## Examples

      iex> get_report!(scope, 123)
      %Report{}

      iex> get_report!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_report!(%Scope{} = scope, id) do
    Repo.get_by!(Report, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a report.

  ## Examples

      iex> create_report(scope, %{field: value})
      {:ok, %Report{}}

      iex> create_report(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_report(%Scope{} = scope, attrs) do
    with {:ok, report = %Report{}} <-
           %Report{}
           |> Report.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_reports(scope, {:created, report})

      %{user_id: scope.user.id, report_id: report.id}
      |> ExAutomation.Jobs.MonthlyReportWorker.new()
      |> Oban.insert()

      {:ok, report}
    end
  end

  @doc """
  Deletes a report.

  ## Examples

      iex> delete_report(scope, report)
      {:ok, %Report{}}

      iex> delete_report(scope, report)
      {:error, %Ecto.Changeset{}}

  """
  def update_report(%Scope{} = scope, %Report{} = report, attrs) do
    true = report.user_id == scope.user.id

    report
    |> Report.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Adds an entry to the report's entries array.

  ## Examples

      iex> add_entry_to_report(scope, report, %{"release_name" => "v1.0.0"})
      {:ok, %Report{}}

  """
  def add_entry_to_report(%Scope{} = scope, %Report{} = report, entry) when is_map(entry) do
    true = report.user_id == scope.user.id
    current_entries = report.entries || []
    new_entries = current_entries ++ [entry]
    update_report(scope, report, %{entries: new_entries})
  end

  @doc """
  Clears all entries from the report.

  ## Examples

      iex> clear_report_entries(scope, report)
      {:ok, %Report{}}

  """
  def clear_report_entries(%Scope{} = scope, %Report{} = report) do
    update_report(scope, report, %{entries: []})
  end

  @doc """
  Deletes a Report.

  ## Examples

      iex> delete_report(scope, report)
      {:ok, %Report{}}

      iex> delete_report(scope, report)
      {:error, %Ecto.Changeset{}}

  """
  def delete_report(%Scope{} = scope, %Report{} = report) do
    true = report.user_id == scope.user.id

    with {:ok, report = %Report{}} <-
           Repo.delete(report) do
      broadcast_reports(scope, {:deleted, report})
      {:ok, report}
    end
  end
end
