defmodule ExAutomation.Jobs.GitlabTagReleaseWorker do
  use Oban.Worker, queue: :data, priority: 3, max_attempts: 5
  alias ExAutomation.Gitlab

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"name" => name}}) do
    release = Gitlab.get_release_by_name!(name)

    tags =
      Regex.scan(~r/\b(?!CVE-)[A-Z]{1,10}-\d{1,10}\b/i, release.description || "")
      |> Enum.map(&hd/1)

    Gitlab.update_release(release, %{tags: tags})

    for tag <- tags do
      ExAutomation.Jobs.JiraFetchIssueWorker.find_ticket(tag, nil)
    end
  end
end
