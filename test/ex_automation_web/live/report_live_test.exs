defmodule ExAutomationWeb.ReportLiveTest do
  use ExAutomationWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExAutomation.ReportingFixtures

  @create_attrs %{name: "some name", year: 42}
  @invalid_attrs %{name: nil, year: nil}

  setup :register_and_log_in_user

  defp create_report(%{scope: scope}) do
    report = report_fixture(scope)

    %{report: report}
  end

  describe "Index" do
    setup [:create_report]

    test "lists all reports", %{conn: conn, report: report} do
      {:ok, _index_live, html} = live(conn, ~p"/reports")

      assert html =~ "Listing Reports"
      assert html =~ report.name
    end

    test "saves new report", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/reports")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Report")
               |> render_click()
               |> follow_redirect(conn, ~p"/reports/new")

      assert render(form_live) =~ "New Report"

      assert form_live
             |> form("#report-form", report: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#report-form", report: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/reports")

      html = render(index_live)
      assert html =~ "Report created successfully"
      assert html =~ "some name"
    end

    test "deletes report in listing", %{conn: conn, report: report} do
      {:ok, index_live, _html} = live(conn, ~p"/reports")

      assert index_live |> element("#reports-#{report.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#reports-#{report.id}")
    end
  end

  describe "Show" do
    setup [:create_report]

    test "displays report", %{conn: conn, report: report} do
      {:ok, _show_live, html} = live(conn, ~p"/reports/#{report}")

      assert html =~ "Report #{report.id}"
      assert html =~ report.name
    end

    test "displays foldable JSON when report has entries", %{conn: conn, scope: scope} do
      # Create a report and then update it with entries (since create_changeset doesn't allow entries)
      report = report_fixture(scope, %{name: "JSON Test Report", year: 2024})

      entries = [
        %{
          "release_name" => "v1.0.0",
          "issue_key" => "TASK-123",
          "issue_summary" => "Test task",
          "issue_type" => "Task",
          "issue_status" => "Done"
        },
        %{
          "release_name" => "v2.0.0",
          "issue_key" => "EPIC-456",
          "issue_summary" => "Test epic",
          "issue_type" => "Epic",
          "issue_status" => "In Progress"
        }
      ]

      {:ok, report} = ExAutomation.Reporting.update_report(scope, report, %{entries: entries})

      {:ok, show_live, html} = live(conn, ~p"/reports/#{report}")

      assert html =~ "Report #{report.id}"
      assert html =~ "JSON Test Report"
      assert html =~ "Entries Count"
      assert html =~ "2"
      assert html =~ "Report Data"
      # Check that foldable JSON viewer is present
      assert html =~ "Expand All"
      assert html =~ "Foldable JSON viewer"
      assert has_element?(show_live, "#json-viewer")
      assert html =~ "Copy JSON"
    end

    test "displays empty state when report has no entries", %{conn: conn, scope: scope} do
      # Create a report without entries (default behavior)
      report = report_fixture(scope, %{name: "Empty Report", year: 2024})

      {:ok, _show_live, html} = live(conn, ~p"/reports/#{report}")

      assert html =~ "Show Report"
      assert html =~ "Empty Report"
      assert html =~ "Entries Count"
      assert html =~ "0"
      assert html =~ "Report Data"
      assert html =~ "No entries available yet"
      assert html =~ "Report may still be processing"
    end
  end

  describe "New" do
    test "does not show completed field in create form", %{conn: conn} do
      {:ok, form_live, html} = live(conn, ~p"/reports/new")

      assert html =~ "New Report"
      assert html =~ "Name"
      assert html =~ "Year"
      # Completed field should not be present in the form
      refute html =~ "Completed"
      refute has_element?(form_live, "input[name='report[completed]']")
    end

    test "create form uses create_changeset which ignores completed field", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/reports/new")

      # Submit form normally (completed field can't be set from UI)
      assert {:ok, index_live, _html} =
               form_live
               |> form("#report-form", report: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/reports")

      # Verify report was created with completed = false (default value)
      html = render(index_live)
      assert html =~ "Report created successfully"
      assert html =~ "some name"
      # In the table, completed should show ✗ (false), not ✓ (true)
      assert html =~ "✗"
      refute html =~ "✓"
    end
  end

  describe "Row clickability" do
    test "completed reports have clickable rows", %{conn: conn, scope: scope} do
      # Create a completed report
      report = report_fixture(scope, %{name: "Completed Report", year: 2024})
      {:ok, report} = ExAutomation.Reporting.update_report(scope, report, %{completed: true})

      {:ok, index_live, _html} = live(conn, ~p"/reports")

      # Check that the cells have the correct data attributes for clickable state
      assert has_element?(index_live, "#reports-#{report.id} span[data-completed='true']")
      refute has_element?(index_live, "#reports-#{report.id} span[class*='opacity-60']")

      # Click the first cell and verify it navigates to show page
      assert {:ok, show_live, _html} =
               index_live
               |> element("#reports-#{report.id} td", "Completed Report")
               |> render_click()
               |> follow_redirect(conn, ~p"/reports/#{report}")

      assert render(show_live) =~ "Report #{report.id}"
      assert render(show_live) =~ "Completed Report"
    end

    test "incomplete reports have non-clickable rows", %{conn: conn, scope: scope} do
      # Create an incomplete report (default completed: false)
      report = report_fixture(scope, %{name: "Incomplete Report", year: 2024})

      {:ok, index_live, _html} = live(conn, ~p"/reports")

      # Check that the cells have the correct data attributes for non-clickable state
      assert has_element?(index_live, "#reports-#{report.id} span[data-completed='false']")
      assert has_element?(index_live, "#reports-#{report.id} span[class*='opacity-60']")

      # Try to click the first cell and verify it does NOT navigate (no JS action)
      # Since incomplete reports have no phx-click, this should not perform any navigation
      # We'll just verify that the row is properly styled and non-interactive
      html = render(index_live)
      assert html =~ "Listing Reports"
      assert html =~ "Incomplete Report"

      # Verify that the incomplete report cell doesn't have navigation action
      # by checking that clicking it returns an empty JS command
      assert_raise ArgumentError, ~r/no push or navigation command found/, fn ->
        index_live
        |> element("#reports-#{report.id} td", "Incomplete Report")
        |> render_click()
      end
    end

    test "mixed completion status shows appropriate styling", %{conn: conn, scope: scope} do
      # Create one completed and one incomplete report
      completed_report = report_fixture(scope, %{name: "Completed Report", year: 2024})

      {:ok, completed_report} =
        ExAutomation.Reporting.update_report(scope, completed_report, %{completed: true})

      incomplete_report = report_fixture(scope, %{name: "Incomplete Report", year: 2024})

      {:ok, index_live, _html} = live(conn, ~p"/reports")

      # Check completed report styling - should have data-completed="true" and no opacity
      assert has_element?(
               index_live,
               "#reports-#{completed_report.id} span[data-completed='true']"
             )

      refute has_element?(index_live, "#reports-#{completed_report.id} span[class*='opacity-60']")

      # Check incomplete report styling - should have data-completed="false" and opacity
      assert has_element?(
               index_live,
               "#reports-#{incomplete_report.id} span[data-completed='false']"
             )

      assert has_element?(
               index_live,
               "#reports-#{incomplete_report.id} span[class*='opacity-60']"
             )
    end
  end

  describe "Foldable JSON viewer" do
    test "displays foldable JSON controls when report has entries", %{conn: conn, scope: scope} do
      report = report_fixture(scope, %{name: "JSON Test Report", year: 2024})

      entries = [
        %{
          "release_name" => "v1.0.0",
          "issue_key" => "TASK-123",
          "issue_summary" => "Test task",
          "issue_type" => "Task",
          "issue_status" => "Done"
        },
        %{
          "release_name" => "v2.0.0",
          "issue_key" => "EPIC-456",
          "issue_summary" => "Test epic",
          "issue_type" => "Epic",
          "issue_status" => "In Progress"
        }
      ]

      {:ok, report} = ExAutomation.Reporting.update_report(scope, report, %{entries: entries})

      {:ok, show_live, html} = live(conn, ~p"/reports/#{report}")

      # Check that foldable JSON controls are present
      assert html =~ "Expand All"
      assert html =~ "Copy JSON"
      assert html =~ "Foldable JSON viewer"

      # Check that JSON viewer container is present
      assert has_element?(show_live, "#json-viewer")
    end

    test "toggle expand/collapse all functionality", %{conn: conn, scope: scope} do
      report = report_fixture(scope, %{name: "JSON Test Report", year: 2024})

      entries = [
        %{
          "release_name" => "v1.0.0",
          "issues" => [
            %{"key" => "TASK-123", "summary" => "Test task"}
          ]
        }
      ]

      {:ok, report} = ExAutomation.Reporting.update_report(scope, report, %{entries: entries})

      {:ok, show_live, _html} = live(conn, ~p"/reports/#{report}")

      # Initially should show "Expand All"
      assert has_element?(show_live, "button", "Expand All")

      # Click expand all
      show_live
      |> element("button", "Expand All")
      |> render_click()

      # Should now show "Collapse All"
      assert has_element?(show_live, "button", "Collapse All")

      # Click collapse all
      show_live
      |> element("button", "Collapse All")
      |> render_click()

      # Should show "Expand All" again
      assert has_element?(show_live, "button", "Expand All")
    end

    test "individual node folding functionality", %{conn: conn, scope: scope} do
      report = report_fixture(scope, %{name: "JSON Test Report", year: 2024})

      entries = [
        %{
          "release_name" => "v1.0.0",
          "issues" => [
            %{"key" => "TASK-123", "summary" => "Test task"}
          ]
        }
      ]

      {:ok, report} = ExAutomation.Reporting.update_report(scope, report, %{entries: entries})

      {:ok, show_live, _html} = live(conn, ~p"/reports/#{report}")

      # Initially should be collapsed, showing [+] button for root
      assert has_element?(show_live, "button", "[+]")
      refute has_element?(show_live, "button", "[-]")

      # Expand the root array
      show_live
      |> element("button[phx-value-path='root']", "[+]")
      |> render_click()

      # Now should have both [+] and [-] buttons (root is expanded, children are collapsed)
      assert has_element?(show_live, "button", "[-]")
      assert has_element?(show_live, "button", "[+]")

      # Collapse the root again
      show_live
      |> element("button[phx-value-path='root']", "[-]")
      |> render_click()

      # Should be back to initial state
      assert has_element?(show_live, "button", "[+]")
      refute has_element?(show_live, "button", "[-]")
    end

    test "does not show foldable JSON when report has no entries", %{conn: conn, scope: scope} do
      report = report_fixture(scope, %{name: "Empty Report", year: 2024})

      {:ok, _show_live, html} = live(conn, ~p"/reports/#{report}")

      # Should not show JSON viewer controls
      refute html =~ "Expand All"
      refute html =~ "Foldable JSON viewer"

      # Should show empty state instead
      assert html =~ "No entries available yet"
      assert html =~ "Report may still be processing"
    end
  end
end
