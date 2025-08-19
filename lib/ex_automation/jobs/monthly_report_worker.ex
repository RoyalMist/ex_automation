defmodule ExAutomation.Jobs.MonthlyReportWorker do
  use Oban.Worker, queue: :reports, priority: 1, max_attempts: 5
  alias ExAutomation.Accounts.Scope
  alias ExAutomation.Accounts.User
  alias ExAutomation.Jira
  alias ExAutomation.Jira.Issue
  alias ExAutomation.Reporting

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "report_id" => report_id, "year" => year}}) do
    scope = Scope.for_user(%User{id: user_id})
    releases = ExAutomation.Gitlab.list_releases_by_year(year)

    for release <- releases do
      case release.tags do
        [] ->
          entry = %{
            "release_name" => release.name,
            "release_date" => NaiveDateTime.to_iso8601(release.date)
          }

          Reporting.add_entry_to_report(scope, report_id, entry)

        tags ->
          for tag <- tags do
            entry =
              create_entry(
                release_name: release.name,
                release_date: NaiveDateTime.to_iso8601(release.date),
                tag: tag
              )

            Reporting.add_entry_to_report(scope, report_id, entry)
          end
      end
    end

    # Mark the report as complete
    Reporting.mark_report_complete(scope, report_id)

    :ok
  end

  defp create_entry(
         release_name: release_name,
         release_date: release_date,
         tag: tag
       ) do
    issue = Jira.get_issue_by_key!(tag)
    initiative = get_initiative(issue)

    {initiative_key, initiative_summary} =
      if initiative.key != issue.key do
        {initiative.key, initiative.summary}
      else
        {"N/A", "N/A"}
      end

    %{
      "release_name" => release_name,
      "release_date" => release_date,
      "issue_key" => issue.key,
      "issue_summary" => issue.summary,
      "issue_type" => issue.type,
      "issue_status" => issue.status,
      "initiative_key" => initiative_key,
      "initiative_summary" => initiative_summary
    }
  end

  defp get_initiative(%Issue{parent_id: parent_id}) when parent_id != nil do
    Jira.get_issue!(parent_id)
  end

  defp get_initiative(issue), do: issue
end
