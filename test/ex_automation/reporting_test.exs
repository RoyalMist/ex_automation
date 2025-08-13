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

    test "update_report/3 with valid data updates the report" do
      scope = user_scope_fixture()
      report = report_fixture(scope)
      update_attrs = %{name: "some updated name", year: 43}

      assert {:ok, %Report{} = report} = Reporting.update_report(scope, report, update_attrs)
      assert report.name == "some updated name"
      assert report.year == 43
    end

    test "update_report/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      report = report_fixture(scope)

      assert_raise MatchError, fn ->
        Reporting.update_report(other_scope, report, %{})
      end
    end

    test "update_report/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      report = report_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Reporting.update_report(scope, report, @invalid_attrs)
      assert report == Reporting.get_report!(scope, report.id)
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

    test "change_report/2 returns a report changeset" do
      scope = user_scope_fixture()
      report = report_fixture(scope)
      assert %Ecto.Changeset{} = Reporting.change_report(scope, report)
    end
  end

  describe "entries" do
    alias ExAutomation.Reporting.Entry

    import ExAutomation.AccountsFixtures, only: [user_scope_fixture: 0]
    import ExAutomation.ReportingFixtures

    @invalid_attrs %{release_name: nil, release_date: nil, issue_key: nil, issue_summary: nil, issue_type: nil, issue_status: nil, initiative_key: nil, initiative_summary: nil}

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
      valid_attrs = %{release_name: "some release_name", release_date: ~N[2025-08-12 12:26:00], issue_key: "some issue_key", issue_summary: "some issue_summary", issue_type: "some issue_type", issue_status: "some issue_status", initiative_key: "some initiative_key", initiative_summary: "some initiative_summary"}
      scope = user_scope_fixture()

      assert {:ok, %Entry{} = entry} = Reporting.create_entry(scope, valid_attrs)
      assert entry.release_name == "some release_name"
      assert entry.release_date == ~N[2025-08-12 12:26:00]
      assert entry.issue_key == "some issue_key"
      assert entry.issue_summary == "some issue_summary"
      assert entry.issue_type == "some issue_type"
      assert entry.issue_status == "some issue_status"
      assert entry.initiative_key == "some initiative_key"
      assert entry.initiative_summary == "some initiative_summary"
      assert entry.user_id == scope.user.id
    end

    test "create_entry/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Reporting.create_entry(scope, @invalid_attrs)
    end

    test "update_entry/3 with valid data updates the entry" do
      scope = user_scope_fixture()
      entry = entry_fixture(scope)
      update_attrs = %{release_name: "some updated release_name", release_date: ~N[2025-08-13 12:26:00], issue_key: "some updated issue_key", issue_summary: "some updated issue_summary", issue_type: "some updated issue_type", issue_status: "some updated issue_status", initiative_key: "some updated initiative_key", initiative_summary: "some updated initiative_summary"}

      assert {:ok, %Entry{} = entry} = Reporting.update_entry(scope, entry, update_attrs)
      assert entry.release_name == "some updated release_name"
      assert entry.release_date == ~N[2025-08-13 12:26:00]
      assert entry.issue_key == "some updated issue_key"
      assert entry.issue_summary == "some updated issue_summary"
      assert entry.issue_type == "some updated issue_type"
      assert entry.issue_status == "some updated issue_status"
      assert entry.initiative_key == "some updated initiative_key"
      assert entry.initiative_summary == "some updated initiative_summary"
    end

    test "update_entry/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      entry = entry_fixture(scope)

      assert_raise MatchError, fn ->
        Reporting.update_entry(other_scope, entry, %{})
      end
    end

    test "update_entry/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      entry = entry_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Reporting.update_entry(scope, entry, @invalid_attrs)
      assert entry == Reporting.get_entry!(scope, entry.id)
    end

    test "delete_entry/2 deletes the entry" do
      scope = user_scope_fixture()
      entry = entry_fixture(scope)
      assert {:ok, %Entry{}} = Reporting.delete_entry(scope, entry)
      assert_raise Ecto.NoResultsError, fn -> Reporting.get_entry!(scope, entry.id) end
    end

    test "delete_entry/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      entry = entry_fixture(scope)
      assert_raise MatchError, fn -> Reporting.delete_entry(other_scope, entry) end
    end

    test "change_entry/2 returns a entry changeset" do
      scope = user_scope_fixture()
      entry = entry_fixture(scope)
      assert %Ecto.Changeset{} = Reporting.change_entry(scope, entry)
    end
  end
end
