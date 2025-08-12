defmodule ExAutomation.Jira do
  import Ecto.Query, warn: false
  alias ExAutomation.Repo

  alias ExAutomation.Jira.Issue
  alias ExAutomation.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any issue changes.

  The broadcasted messages match the pattern:

    * {:created, %Issue{}}
    * {:updated, %Issue{}}
    * {:deleted, %Issue{}}

  """
  def subscribe_issues(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(ExAutomation.PubSub, "user:#{key}:issues")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(ExAutomation.PubSub, "user:#{key}:issues", message)
  end

  @moduledoc """
  The Jira context.
  """

  @doc """
  Fetches a Jira ticket by its ID.

  ## Parameters

    * `ticket_id` - The Jira ticket ID (e.g., "INT-123")
    * `base_url` - The Jira instance base URL (e.g., "https://yourcompany.atlassian.net")
    * `token` - Jira API token for authentication
    * `email` - Email address associated with the API token

  ## Examples

      iex> get_ticket("INT-123", "https://company.atlassian.net", "api_token", "user@company.com")
      {:ok, %{"key" => "INT-123", "fields" => %{"summary" => "Ticket summary", ...}}}

      iex> get_ticket("INVALID-123", "https://company.atlassian.net", "api_token", "user@company.com")
      {:error, %{status: 404, message: "Ticket not found"}}

  """
  @spec get_ticket(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, map()}
  defdelegate get_ticket(ticket_id, base_url, token, email), to: ExAutomation.Jira.Client

  @doc """
  Fetches a Jira ticket by its ID with custom field selection.

  ## Parameters

    * `ticket_id` - The Jira ticket ID (e.g., "INT-123")
    * `base_url` - The Jira instance base URL
    * `token` - Jira API token for authentication
    * `email` - Email address associated with the API token
    * `fields` - List of fields to retrieve

  ## Examples

      iex> get_ticket_with_fields("INT-123", "https://company.atlassian.net", "api_token", "user@company.com", ["summary", "status", "assignee"])
      {:ok, %{"key" => "INT-123", "fields" => %{"summary" => "Ticket summary", "status" => %{...}}}}

  """
  @spec get_ticket_with_fields(String.t(), String.t(), String.t(), String.t(), list(String.t())) ::
          {:ok, map()} | {:error, map()}
  defdelegate get_ticket_with_fields(ticket_id, base_url, token, email, fields),
    to: ExAutomation.Jira.Client

  @doc """
  Returns the list of issues.

  ## Examples

      iex> list_issues(scope)
      [%Issue{}, ...]

  """
  def list_issues(%Scope{} = scope) do
    Repo.all_by(Issue, user_id: scope.user.id)
  end

  @doc """
  Gets a single issue.

  Raises `Ecto.NoResultsError` if the Issue does not exist.

  ## Examples

      iex> get_issue!(scope, 123)
      %Issue{}

      iex> get_issue!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_issue!(%Scope{} = scope, id) do
    Repo.get_by!(Issue, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a issue.

  ## Examples

      iex> create_issue(scope, %{field: value})
      {:ok, %Issue{}}

      iex> create_issue(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_issue(%Scope{} = scope, attrs) do
    with {:ok, issue = %Issue{}} <-
           %Issue{}
           |> Issue.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, issue})
      {:ok, issue}
    end
  end

  @doc """
  Updates a issue.

  ## Examples

      iex> update_issue(scope, issue, %{field: new_value})
      {:ok, %Issue{}}

      iex> update_issue(scope, issue, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_issue(%Scope{} = scope, %Issue{} = issue, attrs) do
    true = issue.user_id == scope.user.id

    with {:ok, issue = %Issue{}} <-
           issue
           |> Issue.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, issue})
      {:ok, issue}
    end
  end

  @doc """
  Deletes a issue.

  ## Examples

      iex> delete_issue(scope, issue)
      {:ok, %Issue{}}

      iex> delete_issue(scope, issue)
      {:error, %Ecto.Changeset{}}

  """
  def delete_issue(%Scope{} = scope, %Issue{} = issue) do
    true = issue.user_id == scope.user.id

    with {:ok, issue = %Issue{}} <-
           Repo.delete(issue) do
      broadcast(scope, {:deleted, issue})
      {:ok, issue}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking issue changes.

  ## Examples

      iex> change_issue(scope, issue)
      %Ecto.Changeset{data: %Issue{}}

  """
  def change_issue(%Scope{} = scope, %Issue{} = issue, attrs \\ %{}) do
    true = issue.user_id == scope.user.id

    Issue.changeset(issue, attrs, scope)
  end
end
