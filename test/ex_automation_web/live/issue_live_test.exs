defmodule ExAutomationWeb.IssueLiveTest do
  use ExAutomationWeb.ConnCase
  import Phoenix.LiveViewTest
  import ExAutomation.JiraFixtures

  setup :register_and_log_in_user

  defp create_issue(%{scope: scope}) do
    issue = issue_fixture(scope)
    %{issue: issue}
  end

  describe "Index" do
    setup [:create_issue]

    test "lists all issues", %{conn: conn, issue: issue} do
      {:ok, _index_live, html} = live(conn, ~p"/issues")

      assert html =~ "Listing Issues"
      assert html =~ issue.key
    end
  end

  describe "Show" do
    setup [:create_issue]

    test "displays issue", %{conn: conn, issue: issue} do
      {:ok, _show_live, html} = live(conn, ~p"/issues/#{issue}")

      assert html =~ "Show Issue"
      assert html =~ issue.key
    end
  end
end
