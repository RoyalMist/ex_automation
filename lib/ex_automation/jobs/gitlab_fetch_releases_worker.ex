defmodule ExAutomation.Jobs.GitlabFetchReleasesWorker do
  use Oban.Worker, queue: :default, priority: 1
  alias ExAutomation.Gitlab.Client

  @impl Oban.Worker
  def perform(%Oban.Job{args: _}) do
    %{page: 1}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{page: page}}) do
    token = System.get_env("GITLAB_TOKEN")
    project = System.get_env("GITLAB_PROJECT_ID")
    {:ok, releases} = Client.list_releases(project, token, page: page)
    create_save_job(releases, page)
  end

  defp create_save_job([], _), do: :ok

  defp create_save_job(releases, page) do
    for release <- releases do
      ExAutomation.Jobs.GitlabSaveReleaseWorker.new(release: release)
      |> Oban.insert()
    end

    %{page: page + 1}
    |> __MODULE__.new()
    |> Oban.insert()
  end
end
