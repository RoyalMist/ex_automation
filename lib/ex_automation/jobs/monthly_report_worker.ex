defmodule ExAutomation.Jobs.MonthlyReportWorker do
  use Oban.Worker, queue: :reports, priority: 1, max_attempts: 5

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"report_id" => report_id, "user_id" => user_id}}) do
    report = ExAutomation.Reporting.get_report!(user_id, report_id)
    _releases = ExAutomation.Gitlab.list_releases_by_year(report.year)
  end
end
