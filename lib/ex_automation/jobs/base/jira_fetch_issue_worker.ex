defmodule ExAutomation.Jobs.Base.JiraFetchIssueWorker do
  require Logger
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

      with {:ok, ticket_data} <- Jira.get_ticket(key, base_url, token, email),
           ticket <- %{
             "key" => ticket_data["key"],
             "summary" => ticket_data["fields"]["summary"],
             "status" => ticket_data["fields"]["status"]["name"],
             "type" => ticket_data["fields"]["issuetype"]["name"],
             "parent_key" => ticket_data["fields"]["parent"]["key"]
           },
           {:ok, _} <- Jira.create_issue(ticket) do
        find_ticket(ticket["parent_key"])
      else
        error ->
          Logger.error("impossible to get jira ticket: #{inspect(error)}")
          error
      end
  end
end
