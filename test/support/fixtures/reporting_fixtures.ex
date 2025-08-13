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
    # Create a report if report_id is not provided
    report_id =
      case Map.get(attrs, :report_id) do
        nil ->
          report = report_fixture(scope)
          report.id

        id ->
          id
      end

    attrs =
      Enum.into(attrs, %{
        release_date: ~N[2025-08-12 12:26:00],
        release_name: "some release_name",
        report_id: report_id
      })

    {:ok, entry} = ExAutomation.Reporting.create_entry(scope, attrs)
    entry
  end
end
