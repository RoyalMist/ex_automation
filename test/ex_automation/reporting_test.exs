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
end
