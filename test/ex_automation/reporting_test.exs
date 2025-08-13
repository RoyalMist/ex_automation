defmodule ExAutomation.ReportingTest do
  use ExAutomation.DataCase
  use Oban.Testing, repo: ExAutomation.Repo

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

    test "MonthlyReportWorker processes releases with tags and creates Jira-enriched entries" do
      import ExAutomation.JiraFixtures

      valid_attrs = %{name: "tagged releases report", year: 2024}
      scope = user_scope_fixture()

      # Create test Jira issues
      parent_issue =
        issue_fixture(%{
          key: "EPIC-123",
          summary: "Main Epic",
          type: "Epic",
          status: "Done"
        })

      child_issue =
        issue_fixture(%{
          key: "TASK-456",
          summary: "Implementation Task",
          type: "Task",
          status: "Done",
          parent_id: parent_issue.id
        })

      # Create releases for 2024 - one without tags, one with tags
      _release_no_tags =
        ExAutomation.GitlabFixtures.release_fixture(%{
          name: "v1.0.0",
          date: ~N[2024-01-15 10:00:00],
          description: "Basic release"
        })

      release_with_tags =
        ExAutomation.GitlabFixtures.release_fixture(%{
          name: "v1.1.0",
          date: ~N[2024-06-15 10:00:00],
          description: "Feature release",
          tags: [child_issue.key]
        })

      # Count entries before
      entries_before = Enum.count(Reporting.list_entries(scope))

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Process the main job that creates basic entries
      perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
        "report_id" => report.id,
        "user_id" => scope.user.id
      })

      # Verify basic entries were created
      entries_after_basic = Reporting.list_entries(scope)
      assert Enum.count(entries_after_basic) == entries_before + 2

      # Find the basic entry for the tagged release
      tagged_release_entry =
        Enum.find(entries_after_basic, &(&1.release_name == "v1.1.0"))

      assert tagged_release_entry != nil
      # Should be nil initially
      assert tagged_release_entry.issue_key == nil

      # Process the tag-specific job for the tagged release
      for tag <- release_with_tags.tags do
        perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
          "user_id" => scope.user.id,
          "report_id" => report.id,
          "release_name" => release_with_tags.name,
          "release_date" => NaiveDateTime.to_iso8601(release_with_tags.date),
          "tag" => tag
        })
      end

      # Verify Jira-enriched entries were created
      entries_final = Reporting.list_entries(scope)
      # 2 basic + 1 enriched
      assert Enum.count(entries_final) == entries_before + 3

      # Find the Jira-enriched entry
      enriched_entry =
        Enum.find(entries_final, fn entry ->
          entry.release_name == "v1.1.0" and entry.issue_key != nil
        end)

      assert enriched_entry != nil
      assert enriched_entry.issue_key == child_issue.key
      assert enriched_entry.issue_summary == child_issue.summary
      assert enriched_entry.issue_type == child_issue.type
      assert enriched_entry.issue_status == child_issue.status
      assert enriched_entry.initiative_key == parent_issue.key
      assert enriched_entry.initiative_summary == parent_issue.summary
      assert enriched_entry.report_id == report.id

      # Verify we have both basic and enriched entries for the same release
      v110_entries = Enum.filter(entries_final, &(&1.release_name == "v1.1.0"))
      assert Enum.count(v110_entries) == 2

      basic_entry = Enum.find(v110_entries, &(&1.issue_key == nil))
      enriched_entry = Enum.find(v110_entries, &(&1.issue_key != nil))

      assert basic_entry != nil
      assert enriched_entry != nil
      assert basic_entry.id != enriched_entry.id
    end

    test "MonthlyReportWorker handles releases with multiple tags and issues without parents" do
      import ExAutomation.JiraFixtures

      valid_attrs = %{name: "multi-tag report", year: 2024}
      scope = user_scope_fixture()

      # Create test Jira issues - one standalone, one with parent
      standalone_issue =
        issue_fixture(%{
          key: "STORY-789",
          summary: "Standalone Story",
          type: "Story",
          status: "Done",
          parent_id: nil
        })

      parent_issue =
        issue_fixture(%{
          key: "EPIC-456",
          summary: "Feature Epic",
          type: "Epic",
          status: "In Progress"
        })

      child_issue =
        issue_fixture(%{
          key: "BUG-101",
          summary: "Critical Bug Fix",
          type: "Bug",
          status: "Fixed",
          parent_id: parent_issue.id
        })

      # Create release with multiple tags
      release_multi_tags =
        ExAutomation.GitlabFixtures.release_fixture(%{
          name: "v2.0.0",
          date: ~N[2024-12-15 10:00:00],
          description: "Major release with multiple features",
          tags: [standalone_issue.key, child_issue.key]
        })

      # Count entries before
      entries_before = Enum.count(Reporting.list_entries(scope))

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Process the main job that creates basic entries
      perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
        "report_id" => report.id,
        "user_id" => scope.user.id
      })

      # Should have 1 basic entry
      entries_after_basic = Reporting.list_entries(scope)
      assert Enum.count(entries_after_basic) == entries_before + 1

      # Process tag-specific jobs for each tag
      for tag <- release_multi_tags.tags do
        perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
          "user_id" => scope.user.id,
          "report_id" => report.id,
          "release_name" => release_multi_tags.name,
          "release_date" => NaiveDateTime.to_iso8601(release_multi_tags.date),
          "tag" => tag
        })
      end

      # Verify all entries were created (1 basic + 2 enriched)
      entries_final = Reporting.list_entries(scope)
      assert Enum.count(entries_final) == entries_before + 3

      # Find entries by release name
      v200_entries = Enum.filter(entries_final, &(&1.release_name == "v2.0.0"))
      assert Enum.count(v200_entries) == 3

      # Verify basic entry
      basic_entry = Enum.find(v200_entries, &(&1.issue_key == nil))
      assert basic_entry != nil

      # Verify standalone issue entry (no parent, so initiative should be same as issue)
      standalone_entry = Enum.find(v200_entries, &(&1.issue_key == standalone_issue.key))
      assert standalone_entry != nil
      assert standalone_entry.issue_key == standalone_issue.key
      assert standalone_entry.issue_summary == standalone_issue.summary
      assert standalone_entry.issue_type == standalone_issue.type
      assert standalone_entry.issue_status == standalone_issue.status
      # Initiative should be nil since it's the same as the issue
      assert standalone_entry.initiative_key == nil
      assert standalone_entry.initiative_summary == nil

      # Verify child issue entry (has parent, so initiative should be parent)
      child_entry = Enum.find(v200_entries, &(&1.issue_key == child_issue.key))
      assert child_entry != nil
      assert child_entry.issue_key == child_issue.key
      assert child_entry.issue_summary == child_issue.summary
      assert child_entry.issue_type == child_issue.type
      assert child_entry.issue_status == child_issue.status
      # Initiative should be parent
      assert child_entry.initiative_key == parent_issue.key
      assert child_entry.initiative_summary == parent_issue.summary

      # All entries should belong to the same report
      Enum.each(v200_entries, fn entry ->
        assert entry.report_id == report.id
        assert entry.user_id == scope.user.id
      end)
    end

    test "MonthlyReportWorker automatically processes tags and enqueues Jira integration jobs" do
      import ExAutomation.JiraFixtures

      valid_attrs = %{name: "auto-tag processing report", year: 2024}
      scope = user_scope_fixture()

      # Create test Jira issue
      issue =
        issue_fixture(%{
          key: "AUTO-123",
          summary: "Automated Feature",
          type: "Story",
          status: "Done"
        })

      # Create releases for 2024 - one without tags, one with tags
      _release_no_tags =
        ExAutomation.GitlabFixtures.release_fixture(%{
          name: "v1.0.0",
          date: ~N[2024-01-15 10:00:00],
          description: "Basic release"
        })

      _release_with_tags =
        ExAutomation.GitlabFixtures.release_fixture(%{
          name: "v1.1.0",
          date: ~N[2024-06-15 10:00:00],
          description: "Feature release",
          tags: [issue.key]
        })

      # Count entries before
      entries_before = Enum.count(Reporting.list_entries(scope))

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Process only the main job - it should automatically enqueue tag-specific jobs
      perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
        "report_id" => report.id,
        "user_id" => scope.user.id
      })

      # At this point we should have 2 basic entries
      entries_after_basic = Reporting.list_entries(scope)
      assert Enum.count(entries_after_basic) == entries_before + 2

      # Check that a tag-specific job was enqueued
      assert_enqueued(
        worker: ExAutomation.Jobs.MonthlyReportWorker,
        args: %{
          "user_id" => scope.user.id,
          "report_id" => report.id,
          "release_name" => "v1.1.0",
          "tag" => issue.key
        }
      )

      # Manually trigger the enqueued tag job to simulate full workflow
      perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
        "user_id" => scope.user.id,
        "report_id" => report.id,
        "release_name" => "v1.1.0",
        "release_date" => "2024-06-15T10:00:00",
        "tag" => issue.key
      })

      # Verify Jira-enriched entry was created (2 basic + 1 enriched)
      entries_final = Reporting.list_entries(scope)
      assert Enum.count(entries_final) == entries_before + 3

      # Find the Jira-enriched entry
      enriched_entry =
        Enum.find(entries_final, fn entry ->
          entry.release_name == "v1.1.0" and entry.issue_key == issue.key
        end)

      assert enriched_entry != nil
      assert enriched_entry.issue_key == issue.key
      assert enriched_entry.issue_summary == issue.summary
      assert enriched_entry.issue_type == issue.type
      assert enriched_entry.issue_status == issue.status
      # Since no parent, initiative should be nil
      assert enriched_entry.initiative_key == nil
      assert enriched_entry.initiative_summary == nil
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
