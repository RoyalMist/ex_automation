defmodule ExAutomation.ReportingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExAutomation.Reporting` context.
  """

  @doc """
  Generate a report.
  """
  def report_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some name",
        year: 42
      })

    {:ok, report} = ExAutomation.Reporting.create_report(scope, attrs)
    report
  end

  @doc """
  Generate a entry.
  """
  def entry_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        initiative_key: "some initiative_key",
        initiative_summary: "some initiative_summary",
        issue_key: "some issue_key",
        issue_status: "some issue_status",
        issue_summary: "some issue_summary",
        issue_type: "some issue_type",
        release_date: ~N[2025-08-12 12:26:00],
        release_name: "some release_name"
      })

    {:ok, entry} = ExAutomation.Reporting.create_entry(scope, attrs)
    entry
  end
end
