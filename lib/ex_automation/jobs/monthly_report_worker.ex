defmodule ExAutomation.Jobs.MonthlyReportWorker do
  use Oban.Worker, queue: :reports, priority: 1, max_attempts: 5
  alias ExAutomation.Reporting
  alias ExAutomation.Accounts.Scope
  alias ExAutomation.Accounts.User

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"report_id" => report_id, "user_id" => user_id}}) do
    scope = %Scope{user: %User{id: user_id}}
    report = Reporting.get_report!(scope, report_id)
    releases = ExAutomation.Gitlab.list_releases_by_year(report.year)

    for release <- releases do
      Reporting.create_entry(scope, %{
        release_name: release.name,
        release_date: release.date
      })
    end
  end
end
