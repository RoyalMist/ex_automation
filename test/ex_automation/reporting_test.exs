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

    @invalid_attrs %{release_name: nil, release_date: nil}

    test "list_entries/1 returns all scoped entries" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      entry = entry_fixture(scope)
      other_entry = entry_fixture(other_scope)
      assert Reporting.list_entries(scope) == [entry]
      assert Reporting.list_entries(other_scope) == [other_entry]
    end

    test "get_entry!/2 returns the entry with given id" do
      scope = user_scope_fixture()
      entry = entry_fixture(scope)
      other_scope = user_scope_fixture()
      assert Reporting.get_entry!(scope, entry.id) == entry
      assert_raise Ecto.NoResultsError, fn -> Reporting.get_entry!(other_scope, entry.id) end
    end

    test "create_entry/2 with valid data creates a entry" do
      valid_attrs = %{release_name: "some release_name", release_date: ~N[2025-08-12 12:26:00]}
      scope = user_scope_fixture()

      assert {:ok, %Entry{} = entry} = Reporting.create_entry(scope, valid_attrs)
      assert entry.release_name == "some release_name"
      assert entry.release_date == ~N[2025-08-12 12:26:00]
      assert entry.user_id == scope.user.id
    end

    test "create_entry/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Reporting.create_entry(scope, @invalid_attrs)
    end

    test "create_entry/2 with only required fields creates a entry" do
      valid_attrs = %{release_name: "minimal release", release_date: ~N[2025-01-01 12:00:00]}
      scope = user_scope_fixture()

      assert {:ok, %Entry{} = entry} = Reporting.create_entry(scope, valid_attrs)
      assert entry.release_name == "minimal release"
      assert entry.release_date == ~N[2025-01-01 12:00:00]
      assert entry.issue_key == nil
      assert entry.issue_summary == nil
      assert entry.issue_type == nil
      assert entry.issue_status == nil
      assert entry.initiative_key == nil
      assert entry.initiative_summary == nil
      assert entry.user_id == scope.user.id
    end

    test "create_entry/2 with optional fields creates a entry" do
      valid_attrs = %{
        release_name: "full release",
        release_date: ~N[2025-01-01 12:00:00],
        issue_key: "TEST-123",
        issue_summary: "Test issue summary",
        issue_type: "Bug",
        issue_status: "Done",
        initiative_key: "INIT-456",
        initiative_summary: "Test initiative"
      }

      scope = user_scope_fixture()

      assert {:ok, %Entry{} = entry} = Reporting.create_entry(scope, valid_attrs)
      assert entry.release_name == "full release"
      assert entry.release_date == ~N[2025-01-01 12:00:00]
      assert entry.issue_key == "TEST-123"
      assert entry.issue_summary == "Test issue summary"
      assert entry.issue_type == "Bug"
      assert entry.issue_status == "Done"
      assert entry.initiative_key == "INIT-456"
      assert entry.initiative_summary == "Test initiative"
      assert entry.user_id == scope.user.id
    end
  end
end
