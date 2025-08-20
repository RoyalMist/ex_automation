defmodule ExAutomation.Jobs.Base.JiraFetchIssueWorker do
  use Oban.Worker, queue: :data, priority: 4, max_attempts: 1
  alias ExAutomation.Jira

  def find_ticket(nil, _), do: :ok

  def find_ticket(key, child_issue_id) do
    metaco = System.get_env("JIRA_METACO")
    ripple = System.get_env("JIRA_RIPPLE")

    %{base_url: metaco, key: key, child_issue_id: child_issue_id}
    |> __MODULE__.new()
    |> Oban.insert()

    %{base_url: ripple, key: key, child_issue_id: child_issue_id}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"base_url" => base_url, "key" => key, "child_issue_id" => child_issue_id}
      }) do
    Jira.get_issue!(key)
    :ok
  rescue
    _ ->
      token = System.get_env("JIRA_TOKEN")
      email = System.get_env("JIRA_EMAIL")

      case Jira.get_ticket(key, base_url, token, email) do
        {:ok, ticket_data} ->
          ticket = %{
            "key" => ticket_data["key"],
            "summary" => ticket_data["fields"]["summary"],
            "status" => ticket_data["fields"]["status"]["name"],
            "type" => ticket_data["fields"]["issuetype"]["name"],
            "parent" => ticket_data["fields"]["parent"]["key"]
          }

          {:ok, issue} = Jira.create_issue(ticket)

          if child_issue_id do
            child = Jira.get_issue!(child_issue_id)
            Jira.update_issue(child, %{parent_id: issue.id})
          end

          find_ticket(ticket["parent"], issue.id)

        error ->
          error
      end
  end
end
