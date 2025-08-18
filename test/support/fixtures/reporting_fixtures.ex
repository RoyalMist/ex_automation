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
end
