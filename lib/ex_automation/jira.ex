defmodule ExAutomation.Jira do
  import Ecto.Query, warn: false
  alias ExAutomation.Repo
  alias ExAutomation.Jira.Issue

  @doc """
  Subscribes to notifications about any issue changes.

  The broadcasted messages match the pattern:

    * {:created, %Issue{}}
    * {:updated, %Issue{}}
    * {:deleted, %Issue{}}

  """
  def subscribe_issues() do
    Phoenix.PubSub.subscribe(ExAutomation.PubSub, "issues")
  end

  defp broadcast(message) do
    Phoenix.PubSub.broadcast(ExAutomation.PubSub, "issues", message)
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

      iex> list_issues()
      [%Issue{}, ...]

  """
  def list_issues() do
    Repo.all(Issue)
  end

  @doc """
  Gets a single issue.

  Raises `Ecto.NoResultsError` if the Issue does not exist.

  ## Examples

      iex> get_issue!(123)
      %Issue{}

      iex> get_issue!(456)
      ** (Ecto.NoResultsError)

  """
  def get_issue!(id) do
    Repo.get_by!(Issue, id: id)
  end

  @doc """
  Creates a issue.

  ## Examples

      iex> create_issue(%{field: value})
      {:ok, %Issue{}}

      iex> create_issue(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_issue(attrs) do
    with {:ok, issue = %Issue{}} <-
           %Issue{}
           |> Issue.changeset(attrs)
           |> Repo.insert() do
      broadcast({:created, issue})
      {:ok, issue}
    end
  end

  @doc """
  Updates a issue.

  ## Examples

      iex> update_issue(issue, %{field: new_value})
      {:ok, %Issue{}}

      iex> update_issue(issue, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_issue(%Issue{} = issue, attrs) do
    with {:ok, issue = %Issue{}} <-
           issue
           |> Issue.changeset(attrs)
           |> Repo.update() do
      broadcast({:updated, issue})
      {:ok, issue}
    end
  end

  @doc """
  Deletes a issue.

  ## Examples

      iex> delete_issue(issue)
      {:ok, %Issue{}}

      iex> delete_issue(issue)
      {:error, %Ecto.Changeset{}}

  """
  def delete_issue(%Issue{} = issue) do
    with {:ok, issue = %Issue{}} <-
           Repo.delete(issue) do
      broadcast({:deleted, issue})
      {:ok, issue}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking issue changes.

  ## Examples

      iex> change_issue(issue)
      %Ecto.Changeset{data: %Issue{}}

  """
  def change_issue(%Issue{} = issue, attrs \\ %{}) do
    Issue.changeset(issue, attrs)
  end
end
