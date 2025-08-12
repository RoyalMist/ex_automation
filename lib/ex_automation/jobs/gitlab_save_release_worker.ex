defmodule ExAutomation.Jobs.GitlabSaveReleaseWorker do
  use Oban.Worker, queue: :default, priority: 2

  @impl Oban.Worker
  def perform(%Oban.Job{args: _release}) do
    :ok
  end
end
