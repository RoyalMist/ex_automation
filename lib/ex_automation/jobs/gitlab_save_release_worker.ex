defmodule ExAutomation.Jobs.GitlabSaveReleaseWorker do
  use Oban.Worker, queue: :gitlab, priority: 2, max_attempts: 2
  alias ExAutomation.Gitlab

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"release" => release}}) do
    try do
      Gitlab.get_release_by_name!(release["name"])
      :ok
    rescue
      _ ->
        Gitlab.create_release(%{
          name: release["name"],
          date: release["released_at"],
          description: release["description"]
        })
    end
  end
end
