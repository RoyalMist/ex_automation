defmodule ExAutomation.Jobs.JiraFetchIssueWorker do
  use Oban.Worker, queue: :data, priority: 4, max_attempts: 5
  alias ExAutomation.Jira

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"base_url" => base_url, "key" => key}}) do
    try do
      Jira.get_issue!(key)
      :ok
    rescue
      _ ->
        token = System.get_env("JIRA_TOKEN")
        email = System.get_env("JIRA_EMAIL")

        case Jira.get_ticket(key, base_url, token, email) do
          {:ok, ticket_data} ->
            # Process the ticket data if needed
            {:ok, ticket_data}

          error ->
            error
        end
    end
  end
end
