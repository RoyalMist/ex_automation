defmodule ExAutomation.JiraFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExAutomation.Jira` context.
  """

  @doc """
  Generate a issue.
  """
  def issue_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        key: "some key",
        parent_key: "some parent_key",
        status: "some status",
        summary: "some summary",
        type: "some type"
      })

    {:ok, issue} = ExAutomation.Jira.create_issue(scope, attrs)
    issue
  end
end
