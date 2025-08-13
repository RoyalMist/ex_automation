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

  defp broadcast(%Scope{} = scope, message) do
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
      broadcast(scope, {:created, report})
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
  def delete_report(%Scope{} = scope, %Report{} = report) do
    true = report.user_id == scope.user.id

    with {:ok, report = %Report{}} <-
           Repo.delete(report) do
      broadcast(scope, {:deleted, report})
      {:ok, report}
    end
  end

  alias ExAutomation.Reporting.Entry
  alias ExAutomation.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any entry changes.

  The broadcasted messages match the pattern:

    * {:created, %Entry{}}

  """
  def subscribe_entries(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(ExAutomation.PubSub, "user:#{key}:entries")
  end

  @doc """
  Returns the list of entries.

  ## Examples

      iex> list_entries(scope)
      [%Entry{}, ...]

  """
  def list_entries(%Scope{} = scope) do
    Repo.all_by(Entry, user_id: scope.user.id)
  end

  @doc """
  Gets a single entry.

  Raises `Ecto.NoResultsError` if the Entry does not exist.

  ## Examples

      iex> get_entry!(scope, 123)
      %Entry{}

      iex> get_entry!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_entry!(%Scope{} = scope, id) do
    Repo.get_by!(Entry, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a entry.

  ## Examples

      iex> create_entry(scope, %{field: value})
      {:ok, %Entry{}}

      iex> create_entry(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_entry(%Scope{} = scope, attrs) do
    with {:ok, entry = %Entry{}} <-
           %Entry{}
           |> Entry.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, entry})
      {:ok, entry}
    end
  end
end
