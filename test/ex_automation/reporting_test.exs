defmodule ExAutomation.ReportingTest do
  use ExAutomation.DataCase

  alias ExAutomation.Reporting

  describe "reports" do
    alias ExAutomation.Reporting.Report

    import ExAutomation.AccountsFixtures, only: [user_scope_fixture: 0]
    import ExAutomation.ReportingFixtures

    @invalid_attrs %{name: nil, year: nil}

    test "list_reports/1 returns all scoped reports" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      report = report_fixture(scope)
      other_report = report_fixture(other_scope)
      assert Reporting.list_reports(scope) == [report]
      assert Reporting.list_reports(other_scope) == [other_report]
    end

    test "get_report!/2 returns the report with given id" do
      scope = user_scope_fixture()
      report = report_fixture(scope)
      other_scope = user_scope_fixture()
      assert Reporting.get_report!(scope, report.id) == report
      assert_raise Ecto.NoResultsError, fn -> Reporting.get_report!(other_scope, report.id) end
    end

    test "create_report/2 with valid data creates a report" do
      valid_attrs = %{name: "some name", year: 42}
      scope = user_scope_fixture()

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)
      assert report.name == "some name"
      assert report.year == 42
      assert report.user_id == scope.user.id
    end

    test "create_report/2 creates entries via MonthlyReportWorker job" do
      valid_attrs = %{name: "test report", year: 2024}
      scope = user_scope_fixture()

      # Create some test releases for the year
      _release1 =
        ExAutomation.GitlabFixtures.release_fixture(%{
          name: "v1.0.0",
          date: ~N[2024-01-15 10:00:00],
          description: "First release"
        })

      _release2 =
        ExAutomation.GitlabFixtures.release_fixture(%{
          name: "v1.1.0",
          date: ~N[2024-06-15 10:00:00],
          description: "Second release"
        })

      # Count entries before
      entries_before = Enum.count(Reporting.list_entries(scope))

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Process the job that was enqueued
      perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
        "report_id" => report.id,
        "user_id" => scope.user.id
      })

      # Verify entries were created
      entries_after = Reporting.list_entries(scope)
      assert Enum.count(entries_after) == entries_before + 2

      # Verify entries have correct release names
      entry_names = Enum.map(entries_after, & &1.release_name)
      assert "v1.0.0" in entry_names
      assert "v1.1.0" in entry_names
    end

    test "MonthlyReportWorker handles year with no releases gracefully" do
      valid_attrs = %{name: "empty year report", year: 2020}
      scope = user_scope_fixture()

      # Count entries before
      entries_before = Enum.count(Reporting.list_entries(scope))

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Process the job that was enqueued (no releases for 2020)
      result =
        perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
          "report_id" => report.id,
          "user_id" => scope.user.id
        })

      # Job should complete successfully even with no releases
      assert result == :ok

      # Verify no new entries were created
      entries_after = Reporting.list_entries(scope)
      assert Enum.count(entries_after) == entries_before
    end

    test "create_report/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Reporting.create_report(scope, @invalid_attrs)
    end

    test "delete_report/2 deletes the report" do
      scope = user_scope_fixture()
      report = report_fixture(scope)
      assert {:ok, %Report{}} = Reporting.delete_report(scope, report)
      assert_raise Ecto.NoResultsError, fn -> Reporting.get_report!(scope, report.id) end
    end

    test "delete_report/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      report = report_fixture(scope)
      assert_raise MatchError, fn -> Reporting.delete_report(other_scope, report) end
    end
  end

  describe "entries" do
    alias ExAutomation.Reporting.Entry

    import ExAutomation.AccountsFixtures, only: [user_scope_fixture: 0]
    import ExAutomation.ReportingFixtures

    @invalid_attrs %{report_id: nil, release_name: nil, release_date: nil}

    test "list_entries/1 returns all scoped entries" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      report = report_fixture(scope)
      other_report = report_fixture(other_scope)
      entry = entry_fixture(scope, %{report_id: report.id})
      other_entry = entry_fixture(other_scope, %{report_id: other_report.id})
      assert Reporting.list_entries(scope) == [entry]
      assert Reporting.list_entries(other_scope) == [other_entry]
    end

    test "get_entry!/2 returns the entry with given id" do
      scope = user_scope_fixture()
      report = report_fixture(scope)
      entry = entry_fixture(scope, %{report_id: report.id})
      other_scope = user_scope_fixture()
      assert Reporting.get_entry!(scope, entry.id) == entry
      assert_raise Ecto.NoResultsError, fn -> Reporting.get_entry!(other_scope, entry.id) end
    end

    test "create_entry/2 with valid data creates a entry (internal API for MonthlyReportWorker)" do
      scope = user_scope_fixture()
      report = report_fixture(scope)

      valid_attrs = %{
        report_id: report.id,
        release_name: "some release_name",
        release_date: ~N[2025-08-12 12:26:00]
      }

      assert {:ok, %Entry{} = entry} = Reporting.create_entry(scope, valid_attrs)
      assert entry.release_name == "some release_name"
      assert entry.release_date == ~N[2025-08-12 12:26:00]
      assert entry.report_id == report.id
      assert entry.user_id == scope.user.id
    end

    test "create_entry/2 with invalid data returns error changeset (internal API)" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Reporting.create_entry(scope, @invalid_attrs)
    end

    test "create_entry/2 with only required fields creates a entry (internal API)" do
      scope = user_scope_fixture()
      report = report_fixture(scope)

      valid_attrs = %{
        report_id: report.id,
        release_name: "minimal release",
        release_date: ~N[2025-01-01 12:00:00]
      }

      assert {:ok, %Entry{} = entry} = Reporting.create_entry(scope, valid_attrs)
      assert entry.release_name == "minimal release"
      assert entry.release_date == ~N[2025-01-01 12:00:00]
      assert entry.report_id == report.id
      assert entry.issue_key == nil
      assert entry.issue_summary == nil
      assert entry.issue_type == nil
      assert entry.issue_status == nil
      assert entry.initiative_key == nil
      assert entry.initiative_summary == nil
      assert entry.user_id == scope.user.id
    end

    test "create_entry/2 with optional fields creates a entry (internal API)" do
      scope = user_scope_fixture()
      report = report_fixture(scope)

      valid_attrs = %{
        report_id: report.id,
        release_name: "full release",
        release_date: ~N[2025-01-01 12:00:00],
        issue_key: "TEST-123",
        issue_summary: "Test issue summary",
        issue_type: "Bug",
        issue_status: "Done",
        initiative_key: "INIT-456",
        initiative_summary: "Test initiative"
      }

      assert {:ok, %Entry{} = entry} = Reporting.create_entry(scope, valid_attrs)
      assert entry.release_name == "full release"
      assert entry.release_date == ~N[2025-01-01 12:00:00]
      assert entry.report_id == report.id
      assert entry.issue_key == "TEST-123"
      assert entry.issue_summary == "Test issue summary"
      assert entry.issue_type == "Bug"
      assert entry.issue_status == "Done"
      assert entry.initiative_key == "INIT-456"
      assert entry.initiative_summary == "Test initiative"
      assert entry.user_id == scope.user.id
    end

    test "delete_report/2 cascades delete to related entries" do
      scope = user_scope_fixture()
      report = report_fixture(scope)

      # Create entries associated with the report
      entry1 = entry_fixture(scope, %{release_name: "Entry 1", report_id: report.id})
      entry2 = entry_fixture(scope, %{release_name: "Entry 2", report_id: report.id})

      # Verify entries exist and are associated with the report
      assert ExAutomation.Repo.get!(Entry, entry1.id).report_id == report.id
      assert ExAutomation.Repo.get!(Entry, entry2.id).report_id == report.id

      # Delete the report
      assert {:ok, %Reporting.Report{}} = Reporting.delete_report(scope, report)

      # Verify report is deleted
      assert_raise Ecto.NoResultsError, fn -> Reporting.get_report!(scope, report.id) end

      # Verify entries are cascade deleted
      assert_raise Ecto.NoResultsError, fn -> ExAutomation.Repo.get!(Entry, entry1.id) end
      assert_raise Ecto.NoResultsError, fn -> ExAutomation.Repo.get!(Entry, entry2.id) end
    end
  end
end
