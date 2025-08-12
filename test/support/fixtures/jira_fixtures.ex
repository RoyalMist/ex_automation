defmodule ExAutomation.JiraFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExAutomation.Jira` context.
  """

  @doc """
  Generate a issue.
  """
  def issue_fixture(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    attrs =
      Enum.into(attrs, %{
        key: "some key #{unique_id}",
        parent_key: "some parent_key",
        status: "some status",
        summary: "some summary",
        type: "some type"
      })

    {:ok, issue} = ExAutomation.Jira.create_issue(attrs)
    issue
  end
end
