defmodule ExAutomation.Jobs.MonthlyReportWorker do
  use Oban.Worker, queue: :reports, priority: 1, max_attempts: 5
  alias ExAutomation.Reporting
  alias ExAutomation.Accounts.Scope

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"scope" => %Scope{} = scope, "report_id" => report_id}}) do
    report = Reporting.get_report!(scope, report_id)
    releases = ExAutomation.Gitlab.list_releases_by_year(report.year)

    for release <- releases do
      Reporting.create_entry(scope, %{
        release_name: release.name,
        release_date: release.date
      })
    end

    :ok
  end
end
