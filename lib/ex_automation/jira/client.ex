defmodule ExAutomation.Jira.Client do
  @moduledoc """
  Jira API client for interacting with Jira tickets.
  """
  require Logger

  @doc """
  Fetches a Jira ticket by its ID.

  ## Parameters

    * `ticket_id` - The Jira ticket ID (e.g., "INT-123")
    * `base_url` - The Jira instance base URL (e.g., "https://yourcompany.atlassian.net")
    * `token` - Jira API token for authentication
    * `email` - Email address associated with the API token

  ## Examples

      iex> ExAutomation.Jira.Client.get_ticket("INT-123", "https://company.atlassian.net", "api_token", "user@company.com")
      {:ok, %{"key" => "INT-123", "fields" => %{"summary" => "Ticket summary", ...}}}

      iex> ExAutomation.Jira.Client.get_ticket("INVALID-123", "https://company.atlassian.net", "api_token", "user@company.com")
      {:error, %{status: 404, body: %{"errorMessages" => ["Issue does not exist or you do not have permission to see it."]}, message: "Ticket not found"}}

      iex> ExAutomation.Jira.Client.get_ticket("INT-123", "https://company.atlassian.net", "invalid_token", "user@company.com")
      {:error, %{status: 401, body: %{"errorMessages" => ["Unauthorized"]}, message: "Authentication failed"}}

  """
  @spec get_ticket(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, map()}
  def get_ticket(ticket_id, base_url, token, email) do
    url = "#{base_url}/rest/api/3/issue/#{ticket_id}"

    # Jira uses Basic Auth with email and API token
    auth_string = Base.encode64("#{email}:#{token}")

    headers = [
      {"Authorization", "Basic #{auth_string}"},
      {"Accept", "application/json"},
      {"Content-Type", "application/json"}
    ]

    Logger.debug("Jira API request: GET #{url}")

    case Req.get(url, headers: headers) do
      {:ok, response} ->
        case response.status do
          200 ->
            {:ok, response.body}

          status when status in [401, 403] ->
            {:error, %{status: status, body: response.body, message: "Authentication failed"}}

          404 ->
            {:error, %{status: 404, body: response.body, message: "Ticket not found"}}

          status when status >= 400 ->
            {:error, %{status: status, body: response.body, message: "API request failed"}}
        end

      {:error, exception} ->
        Logger.error("Jira API request failed: #{inspect(exception)}")
        {:error, %{message: "Network error", details: inspect(exception)}}
    end
  end

  @doc """
  Fetches a Jira ticket by its ID with custom field selection.

  ## Parameters

    * `ticket_id` - The Jira ticket ID (e.g., "INT-123")
    * `base_url` - The Jira instance base URL
    * `token` - Jira API token for authentication
    * `email` - Email address associated with the API token
    * `fields` - List of fields to retrieve (defaults to all fields)

  ## Examples

      iex> ExAutomation.Jira.Client.get_ticket_with_fields("INT-123", "https://company.atlassian.net", "api_token", "user@company.com", ["summary", "status", "assignee"])
      {:ok, %{"key" => "INT-123", "fields" => %{"summary" => "Ticket summary", "status" => %{...}, "assignee" => %{...}}}}

  """
  @spec get_ticket_with_fields(String.t(), String.t(), String.t(), String.t(), list(String.t())) ::
          {:ok, map()} | {:error, map()}
  def get_ticket_with_fields(ticket_id, base_url, token, email, fields) do
    url = "#{base_url}/rest/api/3/issue/#{ticket_id}"

    auth_string = Base.encode64("#{email}:#{token}")

    headers = [
      {"Authorization", "Basic #{auth_string}"},
      {"Accept", "application/json"},
      {"Content-Type", "application/json"}
    ]

    query_params = [
      fields: Enum.join(fields, ",")
    ]

    Logger.debug("Jira API request: GET #{url} with fields: #{inspect(fields)}")

    case Req.get(url, headers: headers, params: query_params) do
      {:ok, response} ->
        case response.status do
          200 ->
            {:ok, response.body}

          status when status in [401, 403] ->
            {:error, %{status: status, body: response.body, message: "Authentication failed"}}

          404 ->
            {:error, %{status: 404, body: response.body, message: "Ticket not found"}}

          status when status >= 400 ->
            {:error, %{status: status, body: response.body, message: "API request failed"}}
        end

      {:error, exception} ->
        Logger.error("Jira API request failed: #{inspect(exception)}")
        {:error, %{message: "Network error", details: inspect(exception)}}
    end
  end
end
