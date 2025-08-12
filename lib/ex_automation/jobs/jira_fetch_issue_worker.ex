defmodule ExAutomation.Jobs.JiraFetchIssueWorker do
  use Oban.Worker, queue: :data, priority: 4, max_attempts: 5
  alias ExAutomation.Jira

  def find_ticket(key) do
    metaco = System.get_env("JIRA_METACO")
    ripple = System.get_env("JIRA_RIPPLE")

    %{base_url: metaco, key: key}
    |> ExAutomation.Jobs.JiraFetchIssueWorker.new()
    |> Oban.insert()

    %{base_url: ripple, key: key}
    |> ExAutomation.Jobs.JiraFetchIssueWorker.new()
    |> Oban.insert()
  end

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
            # We need also to fecth parents
            dbg(ticket_data)
            {:ok, ticket_data}

          error ->
            error
        end
    end
  end
end
