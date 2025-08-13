defmodule ExAutomation.Jobs.MonthlyReportWorker do
  alias ExAutomation.Accounts.User
  use Oban.Worker, queue: :reports, priority: 1, max_attempts: 5
  alias ExAutomation.Reporting
  alias ExAutomation.Accounts.Scope

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "report_id" => report_id}}) do
    scope = Scope.for_user(%User{id: user_id})
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
