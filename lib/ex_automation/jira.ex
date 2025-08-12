defmodule ExAutomation.Jira do
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
end
