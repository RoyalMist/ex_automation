defmodule ExAutomation.Jobs.Base.JiraFetchIssueWorker do
  use Oban.Worker, queue: :data, priority: 4, max_attempts: 1
  alias ExAutomation.Jira

  def find_ticket(nil), do: :ok

  def find_ticket(key) do
    metaco = System.get_env("JIRA_METACO")
    ripple = System.get_env("JIRA_RIPPLE")

    %{base_url: metaco, key: key}
    |> __MODULE__.new()
    |> Oban.insert()

    %{base_url: ripple, key: key}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"base_url" => base_url, "key" => key}
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

          {:ok, _} = Jira.create_issue(ticket)
          find_ticket(ticket["parent"])

        error ->
          error
      end
  end
end
