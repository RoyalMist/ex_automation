defmodule ExAutomation.Jobs.MonthlyReportWorker do
  alias ExAutomation.Jira.Issue
  alias ExAutomation.Jira
  alias ExAutomation.Accounts.User
  use Oban.Worker, queue: :reports, priority: 1, max_attempts: 5
  alias ExAutomation.Reporting
  alias ExAutomation.Accounts.Scope

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "user_id" => user_id,
          "report_id" => report_id,
          "release_name" => release_name,
          "release_date" => release_date,
          "tag" => tag
        }
      }) do
    scope = Scope.for_user(%User{id: user_id})
    issue = Jira.get_issue_by_key!(tag)
    initiative = get_initiative(issue)

    # If the issue has a parent, use parent as initiative; otherwise use the issue itself
    {initiative_key, initiative_summary} =
      if initiative.key != issue.key do
        {initiative.key, initiative.summary}
      else
        {"", ""}
      end

    report = Reporting.get_report!(scope, report_id)

    entry_data = %{
      "release_name" => release_name,
      "release_date" => release_date,
      "issue_key" => issue.key,
      "issue_summary" => issue.summary,
      "issue_type" => issue.type,
      "issue_status" => issue.status,
      "initiative_key" => initiative_key,
      "initiative_summary" => initiative_summary
    }

    Reporting.add_entry_to_report(scope, report, entry_data)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "report_id" => report_id}}) do
    scope = Scope.for_user(%User{id: user_id})
    report = Reporting.get_report!(scope, report_id)
    releases = ExAutomation.Gitlab.list_releases_by_year(report.year)

    for release <- releases do
      # Reload report to ensure we have the latest entries
      current_report = Reporting.get_report!(scope, report_id)

      # Create basic entry for the release
      basic_entry = %{
        "release_name" => release.name,
        "release_date" => NaiveDateTime.to_iso8601(release.date)
      }

      Reporting.add_entry_to_report(scope, current_report, basic_entry)

      # If release has tags, enqueue tag-specific jobs for Jira integration
      for tag <- release.tags do
        %{
          user_id: user_id,
          report_id: report_id,
          release_name: release.name,
          release_date: NaiveDateTime.to_iso8601(release.date),
          tag: tag
        }
        |> ExAutomation.Jobs.MonthlyReportWorker.new()
        |> Oban.insert()
      end
    end

    :ok
  end

  defp get_initiative(%Issue{parent_id: parent_id}) when parent_id != nil do
    Jira.get_issue!(parent_id)
  end

  defp get_initiative(issue), do: issue
end
