defmodule ExAutomation.Jobs.Base.GitlabSaveReleaseWorker do
  use Oban.Worker, queue: :data, priority: 2, max_attempts: 1
  alias ExAutomation.Gitlab
  alias ExAutomation.Jobs.Base.GitlabTagReleaseWorker

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"release" => release}}) do
    Gitlab.get_release_by_name!(release["name"])
    :ok
  rescue
    _ ->
      Gitlab.create_release(%{
        name: release["name"],
        date: release["released_at"],
        description: release["description"]
      })

      %{"name" => release["name"]}
      |> GitlabTagReleaseWorker.new()
      |> Oban.insert()
  end
end
