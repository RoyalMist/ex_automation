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
    * {:updated, %Report{}}
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
  Updates a report.

  ## Examples

      iex> update_report(scope, report, %{field: new_value})
      {:ok, %Report{}}

      iex> update_report(scope, report, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_report(%Scope{} = scope, %Report{} = report, attrs) do
    true = report.user_id == scope.user.id

    with {:ok, report = %Report{}} <-
           report
           |> Report.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, report})
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

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking report changes.

  ## Examples

      iex> change_report(scope, report)
      %Ecto.Changeset{data: %Report{}}

  """
  def change_report(%Scope{} = scope, %Report{} = report, attrs \\ %{}) do
    true = report.user_id == scope.user.id

    Report.changeset(report, attrs, scope)
  end

  alias ExAutomation.Reporting.Entry
  alias ExAutomation.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any entry changes.

  The broadcasted messages match the pattern:

    * {:created, %Entry{}}
    * {:updated, %Entry{}}
    * {:deleted, %Entry{}}

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

  @doc """
  Updates a entry.

  ## Examples

      iex> update_entry(scope, entry, %{field: new_value})
      {:ok, %Entry{}}

      iex> update_entry(scope, entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_entry(%Scope{} = scope, %Entry{} = entry, attrs) do
    true = entry.user_id == scope.user.id

    with {:ok, entry = %Entry{}} <-
           entry
           |> Entry.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, entry})
      {:ok, entry}
    end
  end

  @doc """
  Deletes a entry.

  ## Examples

      iex> delete_entry(scope, entry)
      {:ok, %Entry{}}

      iex> delete_entry(scope, entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_entry(%Scope{} = scope, %Entry{} = entry) do
    true = entry.user_id == scope.user.id

    with {:ok, entry = %Entry{}} <-
           Repo.delete(entry) do
      broadcast(scope, {:deleted, entry})
      {:ok, entry}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking entry changes.

  ## Examples

      iex> change_entry(scope, entry)
      %Ecto.Changeset{data: %Entry{}}

  """
  def change_entry(%Scope{} = scope, %Entry{} = entry, attrs \\ %{}) do
    true = entry.user_id == scope.user.id

    Entry.changeset(entry, attrs, scope)
  end
end
