defmodule ExAutomation.Jobs.Base.GitlabTagReleaseWorker do
  use Oban.Worker, queue: :data, priority: 3, max_attempts: 2
  alias ExAutomation.Gitlab
  alias ExAutomation.Jobs.Base.JiraFetchIssueWorker

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"name" => name}}) do
    release = Gitlab.get_release_by_name!(name)

    tags =
      Regex.scan(~r/\b(?!CVE-)[A-Z]{2,4}-\d{1,10}\b/i, release.description || "")
      |> Enum.map(&hd/1)

    Gitlab.update_release(release, %{tags: tags})

    for tag <- tags do
      JiraFetchIssueWorker.find_ticket(tag, nil)
    end

    :ok
  end
end
