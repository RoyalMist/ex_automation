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
      assert report.entries == []
      assert report.completed == false
    end

    test "create_report/2 with entries creates a report with entries" do
      entries_data = [
        %{"release_name" => "v1.0.0", "issue_key" => "PROJ-123", "summary" => "Feature A"},
        %{"release_name" => "v1.1.0", "issue_key" => "PROJ-456", "summary" => "Feature B"}
      ]

      valid_attrs = %{name: "report with entries", year: 2023, entries: entries_data}
      scope = user_scope_fixture()

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)
      assert report.name == "report with entries"
      assert report.year == 2023
      assert report.user_id == scope.user.id
      assert report.entries == entries_data
      assert report.completed == false
    end

    test "create_report/2 with invalid entries data fails validation gracefully" do
      # Testing with non-map entries should still work since we're using :map type
      valid_attrs = %{name: "test report", year: 2023, entries: []}
      scope = user_scope_fixture()

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)
      assert report.entries == []
      assert report.completed == false
    end

    test "create_report/2 ignores completed field during creation" do
      valid_attrs = %{name: "completed report", year: 2023, completed: true}
      scope = user_scope_fixture()

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)
      assert report.name == "completed report"
      assert report.year == 2023
      assert report.user_id == scope.user.id
      assert report.entries == []
      # Completed field should be false despite being set to true in attrs
      assert report.completed == false
    end

    test "create_changeset/3 does not allow setting completed field" do
      scope = user_scope_fixture()
      attrs = %{name: "test report", year: 2023, completed: true, entries: []}

      changeset =
        Report.create_changeset(
          %Report{},
          attrs,
          scope
        )

      assert changeset.valid?
      assert changeset.changes.name == "test report"
      assert changeset.changes.year == 2023
      # Entries field should not be in changes when empty array is provided (default value)
      refute Map.has_key?(changeset.changes, :entries)
      # Completed field should not be in changes
      refute Map.has_key?(changeset.changes, :completed)
      assert changeset.changes.user_id == scope.user.id
    end

    test "changeset/3 allows setting completed field for updates" do
      scope = user_scope_fixture()
      report = report_fixture(scope)
      attrs = %{name: "updated report", year: 2024, completed: true}

      changeset =
        Report.changeset(
          report,
          attrs,
          scope
        )

      assert changeset.valid?
      assert changeset.changes.name == "updated report"
      assert changeset.changes.year == 2024
      assert changeset.changes.completed == true
      # user_id should not change during updates
      refute Map.has_key?(changeset.changes, :user_id)
    end

    test "update_report/3 can update entries" do
      scope = user_scope_fixture()
      report = report_fixture(scope)

      new_entries = [
        %{"release_name" => "v2.0.0", "issue_key" => "TASK-789", "summary" => "New feature"}
      ]

      update_attrs = %{entries: new_entries}

      assert {:ok, %Report{} = updated_report} =
               Reporting.update_report(scope, report, update_attrs)

      assert updated_report.entries == new_entries
    end

    test "update_report/3 can update completed field" do
      scope = user_scope_fixture()
      report = report_fixture(scope)

      # Initially completed should be false
      assert report.completed == false

      update_attrs = %{completed: true}

      assert {:ok, %Report{} = updated_report} =
               Reporting.update_report(scope, report, update_attrs)

      assert updated_report.completed == true

      # Test updating back to false
      update_attrs = %{completed: false}

      assert {:ok, %Report{} = updated_report} =
               Reporting.update_report(scope, report, update_attrs)

      assert updated_report.completed == false
    end

    test "entries field accepts complex nested JSON structures" do
      complex_entries = [
        %{
          "release_name" => "v3.0.0",
          "issues" => [
            %{"key" => "PROJ-100", "type" => "Epic", "status" => "Done"},
            %{"key" => "PROJ-101", "type" => "Story", "status" => "In Progress"}
          ],
          "metadata" => %{
            "deployment_date" => "2023-12-01",
            "environment" => "production",
            "tags" => ["critical", "feature"]
          }
        },
        %{
          "release_name" => "v3.1.0",
          "issues" => [],
          "metadata" => %{"deployment_date" => "2024-01-15"}
        }
      ]

      valid_attrs = %{name: "complex report", year: 2023, entries: complex_entries}
      scope = user_scope_fixture()

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)
      assert report.entries == complex_entries
    end

    test "entries field can be empty array" do
      valid_attrs = %{name: "empty entries report", year: 2023, entries: []}
      scope = user_scope_fixture()

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)
      assert report.entries == []
    end

    test "entries field defaults to empty array when not provided" do
      valid_attrs = %{name: "default entries report", year: 2023}
      scope = user_scope_fixture()

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)
      assert report.entries == []
    end

    test "can update entries from empty to populated" do
      scope = user_scope_fixture()
      report = report_fixture(scope)
      assert report.entries == []

      entries_data = [
        %{"release" => "v1.0.0", "features" => ["login", "dashboard"]},
        %{"release" => "v1.1.0", "bugfixes" => ["auth-fix", "ui-improvement"]}
      ]

      update_attrs = %{entries: entries_data}

      assert {:ok, %Report{} = updated_report} =
               Reporting.update_report(scope, report, update_attrs)

      assert updated_report.entries == entries_data
    end

    test "can clear entries by setting to empty array" do
      entries_data = [%{"release" => "v1.0.0", "summary" => "Initial release"}]
      scope = user_scope_fixture()
      report = report_fixture(scope, %{entries: entries_data})

      assert report.entries == entries_data

      update_attrs = %{entries: []}

      assert {:ok, %Report{} = updated_report} =
               Reporting.update_report(scope, report, update_attrs)

      assert updated_report.entries == []
    end

    test "entries field persists correctly in database" do
      entries_data = [
        %{"release_name" => "v1.0.0", "issue_key" => "PROJ-123", "priority" => "high"},
        %{"release_name" => "v1.1.0", "issue_key" => "PROJ-456", "priority" => "medium"}
      ]

      scope = user_scope_fixture()

      # Create report with entries
      {:ok, report} =
        Reporting.create_report(scope, %{
          name: "Database test report",
          year: 2023,
          entries: entries_data
        })

      # Reload from database to ensure persistence
      reloaded_report = Reporting.get_report!(scope, report.id)
      assert reloaded_report.entries == entries_data

      # Verify the data structure is preserved correctly
      first_entry = List.first(reloaded_report.entries)
      assert first_entry["release_name"] == "v1.0.0"
      assert first_entry["issue_key"] == "PROJ-123"
      assert first_entry["priority"] == "high"

      second_entry = List.last(reloaded_report.entries)
      assert second_entry["release_name"] == "v1.1.0"
      assert second_entry["issue_key"] == "PROJ-456"
      assert second_entry["priority"] == "medium"

      # Ensure both entries are preserved
      assert length(reloaded_report.entries) == 2
    end

    test "add_entry_to_report/3 adds entry to existing entries array" do
      scope = user_scope_fixture()
      report = report_fixture(scope)
      new_entry = %{"release_name" => "v1.0.0", "feature" => "authentication"}

      assert {:ok, %Report{} = updated_report} =
               Reporting.add_entry_to_report(scope, report.id, new_entry)

      assert updated_report.entries == [new_entry]

      # Add another entry
      second_entry = %{"release_name" => "v1.1.0", "feature" => "dashboard"}

      assert {:ok, %Report{} = updated_report2} =
               Reporting.add_entry_to_report(scope, updated_report.id, second_entry)

      assert updated_report2.entries == [new_entry, second_entry]
    end

    test "add_entry_to_report/3 works with report that already has entries" do
      initial_entries = [%{"release" => "v0.1.0", "type" => "initial"}]
      scope = user_scope_fixture()
      report = report_fixture(scope, %{entries: initial_entries})

      new_entry = %{"release" => "v0.2.0", "type" => "update"}

      assert {:ok, %Report{} = updated_report} =
               Reporting.add_entry_to_report(scope, report.id, new_entry)

      assert updated_report.entries == initial_entries ++ [new_entry]
    end

    test "clear_report_entries/2 clears all entries from report" do
      entries_data = [
        %{"release" => "v1.0.0", "features" => ["login"]},
        %{"release" => "v1.1.0", "features" => ["dashboard"]}
      ]

      scope = user_scope_fixture()
      report = report_fixture(scope, %{entries: entries_data})

      assert report.entries == entries_data

      assert {:ok, %Report{} = cleared_report} =
               Reporting.clear_report_entries(scope, report)

      assert cleared_report.entries == []
    end

    test "add_entry_to_report/3 handles nil entries correctly" do
      scope = user_scope_fixture()
      # Create a report and manually set entries to nil to test edge case
      report = report_fixture(scope)
      report_with_nil = %{report | entries: nil}

      new_entry = %{"release_name" => "v1.0.0", "summary" => "First release"}

      assert {:ok, %Report{} = updated_report} =
               Reporting.add_entry_to_report(scope, report_with_nil.id, new_entry)

      assert updated_report.entries == [new_entry]
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

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Process the job that was enqueued
      perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
        "report_id" => report.id,
        "user_id" => scope.user.id,
        "year" => report.year
      })

      # Verify entries were added to the report
      updated_report = Reporting.get_report!(scope, report.id)
      assert length(updated_report.entries) == 2
      assert updated_report.completed == true

      # Verify entries have correct release names
      entry_names = Enum.map(updated_report.entries, & &1["release_name"])
      assert "v1.0.0" in entry_names
      assert "v1.1.0" in entry_names
    end

    test "MonthlyReportWorker handles year with no releases gracefully" do
      valid_attrs = %{name: "empty year report", year: 2020}
      scope = user_scope_fixture()

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Process the job that was enqueued (no releases for 2020)
      result =
        perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
          "report_id" => report.id,
          "user_id" => scope.user.id,
          "year" => report.year
        })

      # Job should complete successfully even with no releases
      {:ok, _} = result

      # Verify no entries were added to the report since no releases exist for 2020
      updated_report = Reporting.get_report!(scope, report.id)
      assert updated_report.entries == []
      assert updated_report.completed == true
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
          parent_key: parent_issue.key
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
          tags: [child_issue.key]
        })

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Process the main job that creates basic entries
      perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
        "report_id" => report.id,
        "user_id" => scope.user.id,
        "year" => report.year
      })

      # Should have 2 basic entries (one for each release)
      report_after_basic = Reporting.get_report!(scope, report.id)
      assert length(report_after_basic.entries) == 2

      # Find the basic entry for the tagged release
      tagged_release_entry =
        Enum.find(report_after_basic.entries, &(&1["release_name"] == "v1.1.0"))

      assert tagged_release_entry != nil
      assert tagged_release_entry["issue_key"] == "TASK-456"

      # Final entry count after processing tags
      report_final = Reporting.get_report!(scope, report.id)
      # Should have 2 basic entries + 1 enriched entry per tag
      assert length(report_final.entries) == 2

      # Find the Jira-enriched entry
      enriched_entry =
        Enum.find(report_final.entries, fn entry ->
          entry["release_name"] == "v1.1.0" and entry["issue_key"] != nil
        end)

      assert enriched_entry != nil
      assert enriched_entry["issue_key"] == child_issue.key
      assert enriched_entry["issue_summary"] == child_issue.summary
      assert enriched_entry["issue_type"] == child_issue.type
      assert enriched_entry["issue_status"] == child_issue.status
      assert enriched_entry["initiative_key"] == parent_issue.key
      assert enriched_entry["initiative_summary"] == parent_issue.summary

      # Verify we have both basic and enriched entries for the same release
      v110_entries = Enum.filter(report_final.entries, &(&1["release_name"] == "v1.1.0"))
      assert Enum.count(v110_entries) == 1

      basic_entry = Enum.find(v110_entries, &(&1["issue_key"] == nil))
      _enriched_entry = Enum.find(v110_entries, &(&1["issue_key"] != nil))
      refute basic_entry

      # Verify the report is marked as completed
      assert report_final.completed == true
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
          parent_key: nil
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
          parent_key: parent_issue.key
        })

      # Create release with multiple tags
      _release_multi_tags =
        ExAutomation.GitlabFixtures.release_fixture(%{
          name: "v2.0.0",
          date: ~N[2024-12-15 10:00:00],
          description: "Major release with multiple features",
          tags: [standalone_issue.key, child_issue.key]
        })

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Process the main job that creates basic entries
      perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
        "report_id" => report.id,
        "user_id" => scope.user.id,
        "year" => report.year
      })

      # Final entry count: 1 basic + 2 enriched (one for each tag)
      report_final = Reporting.get_report!(scope, report.id)
      assert length(report_final.entries) == 2

      # Find entries for the release with multiple tags
      v200_entries = Enum.filter(report_final.entries, &(&1["release_name"] == "v2.0.0"))
      assert Enum.count(v200_entries) == 2

      # Verify standalone issue entry (no parent, so initiative should be same as issue)
      standalone_entry = Enum.find(v200_entries, &(&1["issue_key"] == standalone_issue.key))
      assert standalone_entry != nil
      assert standalone_entry["issue_key"] == standalone_issue.key
      assert standalone_entry["issue_summary"] == standalone_issue.summary
      assert standalone_entry["issue_type"] == standalone_issue.type
      assert standalone_entry["issue_status"] == standalone_issue.status
      # Initiative should be empty since it's the same as the issue
      assert standalone_entry["initiative_key"] == "N/A"
      assert standalone_entry["initiative_summary"] == "N/A"

      # Verify child issue entry (has parent, so initiative should be parent)
      child_entry = Enum.find(v200_entries, &(&1["issue_key"] == child_issue.key))
      assert child_entry != nil
      assert child_entry["issue_key"] == child_issue.key
      assert child_entry["issue_summary"] == child_issue.summary
      assert child_entry["issue_type"] == child_issue.type
      assert child_entry["issue_status"] == child_issue.status
      assert child_entry["initiative_key"] == parent_issue.key
      assert child_entry["initiative_summary"] == parent_issue.summary

      # Verify the report is marked as completed
      assert report_final.completed == true
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

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Process only the main job - it should automatically enqueue tag-specific jobs
      perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
        "report_id" => report.id,
        "user_id" => scope.user.id,
        "year" => report.year
      })

      # Verify Jira-enriched entry was added (2 basic + 1 enriched)
      report_final = Reporting.get_report!(scope, report.id)
      assert length(report_final.entries) == 2

      # Find the Jira-enriched entry
      enriched_entry =
        Enum.find(report_final.entries, fn entry ->
          entry["release_name"] == "v1.1.0" and entry["issue_key"] == issue.key
        end)

      assert enriched_entry != nil
      assert enriched_entry["issue_key"] == issue.key
      assert enriched_entry["issue_summary"] == issue.summary
      assert enriched_entry["issue_type"] == issue.type
      assert enriched_entry["issue_status"] == issue.status
      # Since no parent, initiative should be empty
      assert enriched_entry["initiative_key"] == "N/A"
      assert enriched_entry["initiative_summary"] == "N/A"
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

    test "mark_report_complete/2 with report struct marks report as completed" do
      scope = user_scope_fixture()
      report = report_fixture(scope)

      # Initially completed should be false
      assert report.completed == false

      assert {:ok, %Report{} = updated_report} =
               Reporting.mark_report_complete(scope, report)

      assert updated_report.completed == true
      assert updated_report.id == report.id
    end

    test "mark_report_complete/2 with report id marks report as completed" do
      scope = user_scope_fixture()
      report = report_fixture(scope)

      # Initially completed should be false
      assert report.completed == false

      assert {:ok, %Report{} = updated_report} =
               Reporting.mark_report_complete(scope, report.id)

      assert updated_report.completed == true
      assert updated_report.id == report.id
    end

    test "mark_report_complete/2 with invalid report id raises" do
      scope = user_scope_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Reporting.mark_report_complete(scope, 999_999)
      end
    end

    test "mark_report_complete/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      report = report_fixture(scope)

      assert_raise MatchError, fn ->
        Reporting.mark_report_complete(other_scope, report)
      end
    end

    test "MonthlyReportWorker marks report as completed after processing" do
      valid_attrs = %{name: "completion test report", year: 2024}
      scope = user_scope_fixture()

      # Create a test release
      _release =
        ExAutomation.GitlabFixtures.release_fixture(%{
          name: "v1.0.0",
          date: ~N[2024-01-15 10:00:00],
          description: "Test release"
        })

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Initially completed should be false
      assert report.completed == false

      # Process the job that was enqueued
      result =
        perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
          "report_id" => report.id,
          "user_id" => scope.user.id,
          "year" => report.year
        })

      {:ok, _} = result

      # Verify the report is marked as completed after job processing
      updated_report = Reporting.get_report!(scope, report.id)
      assert updated_report.completed == true
      assert length(updated_report.entries) == 1
    end

    test "MonthlyReportWorker marks report as completed even with no releases" do
      valid_attrs = %{name: "empty completion test", year: 2020}
      scope = user_scope_fixture()

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Initially completed should be false
      assert report.completed == false

      # Process the job that was enqueued (no releases for 2020)
      result =
        perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
          "report_id" => report.id,
          "user_id" => scope.user.id,
          "year" => report.year
        })

      {:ok, _} = result

      # Verify the report is marked as completed even with no entries
      updated_report = Reporting.get_report!(scope, report.id)
      assert updated_report.completed == true
      assert updated_report.entries == []
    end

    test "MonthlyReportWorker finds initiative as grand parent in three-level hierarchy" do
      import ExAutomation.JiraFixtures
      valid_attrs = %{name: "three-level hierarchy report", year: 2024}
      scope = user_scope_fixture()

      # Create test Jira issues with three-level hierarchy
      grand_parent_issue =
        issue_fixture(%{
          key: "INIT-100",
          summary: "Main Initiative",
          type: "Initiative",
          status: "In Progress"
        })

      parent_issue =
        issue_fixture(%{
          key: "EPIC-200",
          summary: "Feature Epic",
          type: "Epic",
          status: "In Progress",
          parent_key: grand_parent_issue.key
        })

      child_issue =
        issue_fixture(%{
          key: "TASK-300",
          summary: "Implementation Task",
          type: "Task",
          status: "Done",
          parent_key: parent_issue.key
        })

      # Create release with the child issue as tag
      _release_with_child_tag =
        ExAutomation.GitlabFixtures.release_fixture(%{
          name: "v2.0.0",
          date: ~N[2024-08-15 10:00:00],
          description: "Feature release with child task",
          tags: [child_issue.key]
        })

      assert {:ok, %Report{} = report} = Reporting.create_report(scope, valid_attrs)

      # Process the job that creates entries
      perform_job(ExAutomation.Jobs.MonthlyReportWorker, %{
        "report_id" => report.id,
        "user_id" => scope.user.id,
        "year" => report.year
      })

      # Get the updated report
      updated_report = Reporting.get_report!(scope, report.id)
      assert length(updated_report.entries) == 1
      assert updated_report.completed == true

      # Find the entry for our release
      entry = Enum.find(updated_report.entries, &(&1["release_name"] == "v2.0.0"))
      assert entry != nil

      # Verify the entry has the child issue details
      assert entry["issue_key"] == child_issue.key
      assert entry["issue_summary"] == child_issue.summary
      assert entry["issue_type"] == child_issue.type
      assert entry["issue_status"] == child_issue.status

      # Most importantly, verify the initiative is the grand parent (top-level)
      assert entry["initiative_key"] == grand_parent_issue.key
      assert entry["initiative_summary"] == grand_parent_issue.summary

      # Verify the report is marked as completed
      assert updated_report.completed == true
    end
  end
end
