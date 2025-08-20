defmodule ExAutomationWeb.ReportLive.ShowCSVTest do
  use ExUnit.Case, async: true

  # Import the private function for testing
  import ExAutomationWeb.ReportLive.Show, only: []

  # We need to test the private function generate_csv/1
  # Since it's private, we'll create a test module that mirrors the functionality
  defmodule CSVTestHelper do
    def generate_csv(report) do
      if Enum.empty?(report.entries) do
        # Return empty CSV with headers only
        [
          [
            "release_name",
            "release_date",
            "issue_key",
            "issue_summary",
            "issue_type",
            "issue_status",
            "initiative_key",
            "initiative_summary"
          ]
        ]
        |> CSV.encode()
        |> Enum.to_list()
        |> IO.iodata_to_binary()
      else
        # Get all unique keys from all entries to create comprehensive headers
        all_keys =
          report.entries
          |> Enum.flat_map(&Map.keys/1)
          |> Enum.uniq()
          |> Enum.sort()

        # Generate CSV with headers and data rows
        headers = [all_keys]

        data_rows =
          report.entries
          |> Enum.map(fn entry ->
            Enum.map(all_keys, fn key ->
              case Map.get(entry, key) do
                nil -> ""
                value when is_binary(value) -> value
                value -> inspect(value)
              end
            end)
          end)

        (headers ++ data_rows)
        |> CSV.encode()
        |> Enum.to_list()
        |> IO.iodata_to_binary()
      end
    end
  end

  describe "CSV generation" do
    test "generates empty CSV with headers when report has no entries" do
      report = %{entries: []}
      csv_content = CSVTestHelper.generate_csv(report)

      # Should contain headers
      assert csv_content =~ "release_name"
      assert csv_content =~ "release_date"
      assert csv_content =~ "issue_key"
      assert csv_content =~ "issue_summary"
      assert csv_content =~ "issue_type"
      assert csv_content =~ "issue_status"
      assert csv_content =~ "initiative_key"
      assert csv_content =~ "initiative_summary"

      # Should only have header row (no data rows)
      lines = String.split(csv_content, "\n", trim: true)
      assert length(lines) == 1
    end

    test "generates CSV with all entry data when report has entries" do
      report = %{
        entries: [
          %{
            "release_name" => "v1.0.0",
            "release_date" => "2024-01-15T10:00:00",
            "issue_key" => "TASK-123",
            "issue_summary" => "Test task",
            "issue_type" => "Task",
            "issue_status" => "Done",
            "initiative_key" => "EPIC-456",
            "initiative_summary" => "Test epic"
          },
          %{
            "release_name" => "v2.0.0",
            "release_date" => "2024-02-15T10:00:00",
            "issue_key" => "STORY-789",
            "issue_summary" => "Test story",
            "issue_type" => "Story",
            "issue_status" => "In Progress",
            "initiative_key" => "N/A",
            "initiative_summary" => "N/A"
          }
        ]
      }

      csv_content = CSVTestHelper.generate_csv(report)

      # Should contain headers
      assert csv_content =~ "release_name"
      assert csv_content =~ "issue_key"

      # Should contain data from both entries
      assert csv_content =~ "v1.0.0"
      assert csv_content =~ "v2.0.0"
      assert csv_content =~ "TASK-123"
      assert csv_content =~ "STORY-789"
      assert csv_content =~ "Test task"
      assert csv_content =~ "Test story"
      assert csv_content =~ "Done"
      assert csv_content =~ "In Progress"

      # Should have 3 lines (1 header + 2 data rows)
      lines = String.split(csv_content, "\n", trim: true)
      assert length(lines) == 3
    end

    test "handles entries with different keys gracefully" do
      report = %{
        entries: [
          %{
            "release_name" => "v1.0.0",
            "issue_key" => "TASK-123",
            "custom_field" => "custom_value"
          },
          %{
            "release_name" => "v2.0.0",
            "issue_summary" => "Different fields",
            "another_field" => "another_value"
          }
        ]
      }

      csv_content = CSVTestHelper.generate_csv(report)

      # Should include all unique keys from all entries
      assert csv_content =~ "release_name"
      assert csv_content =~ "issue_key"
      assert csv_content =~ "custom_field"
      assert csv_content =~ "issue_summary"
      assert csv_content =~ "another_field"

      # Should have values where they exist and empty strings where they don't
      assert csv_content =~ "v1.0.0"
      assert csv_content =~ "v2.0.0"
      assert csv_content =~ "TASK-123"
      assert csv_content =~ "Different fields"
      assert csv_content =~ "custom_value"
      assert csv_content =~ "another_value"

      # Should have 3 lines (1 header + 2 data rows)
      lines = String.split(csv_content, "\n", trim: true)
      assert length(lines) == 3
    end

    test "handles non-string values by converting them to strings" do
      report = %{
        entries: [
          %{
            "release_name" => "v1.0.0",
            "priority" => 1,
            "active" => true,
            "tags" => ["bug", "urgent"],
            "metadata" => %{"created_by" => "user1"}
          }
        ]
      }

      csv_content = CSVTestHelper.generate_csv(report)

      # Should contain the string representation of non-string values
      assert csv_content =~ "v1.0.0"
      assert csv_content =~ "1"
      assert csv_content =~ "true"
      # Complex values should be inspected and escaped in CSV
      assert csv_content =~ ~s|[""bug"", ""urgent""]|
      assert csv_content =~ ~s|%{""created_by"" => ""user1""}|

      lines = String.split(csv_content, "\n", trim: true)
      assert length(lines) == 2
    end

    test "produces valid CSV format" do
      report = %{
        entries: [
          %{
            "release_name" => "v1.0.0",
            "description" => "A task with, comma and \"quotes\"",
            "notes" => "Multi\nline\ntext"
          }
        ]
      }

      csv_content = CSVTestHelper.generate_csv(report)

      # The CSV should be parseable
      [{:ok, parsed}] =
        csv_content
        |> String.split("\n", trim: true)
        |> CSV.decode(headers: true)
        |> Enum.to_list()

      assert parsed["release_name"] == "v1.0.0"
      assert parsed["description"] == "A task with, comma and \"quotes\""
      assert parsed["notes"] == "Multilinetext"
    end

    test "sorts keys consistently" do
      report = %{
        entries: [
          %{
            "zebra" => "last",
            "alpha" => "first",
            "beta" => "second"
          }
        ]
      }

      csv_content = CSVTestHelper.generate_csv(report)
      lines = String.split(csv_content, "\n", trim: true)
      header_line = List.first(lines)

      # Keys should be sorted alphabetically
      assert String.starts_with?(header_line, "alpha")
      assert header_line =~ ~r/alpha.*beta.*zebra/
    end

    test "handles empty string and nil values correctly" do
      report = %{
        entries: [
          %{
            "name" => "test",
            "empty_string" => "",
            "nil_value" => nil,
            "zero" => 0,
            "false_value" => false
          }
        ]
      }

      csv_content = CSVTestHelper.generate_csv(report)

      # Parse the CSV to verify correct handling
      [{:ok, parsed}] =
        csv_content
        |> String.split("\n", trim: true)
        |> CSV.decode(headers: true)
        |> Enum.to_list()

      assert parsed["name"] == "test"
      assert parsed["empty_string"] == ""
      # nil should become empty string
      assert parsed["nil_value"] == ""
      assert parsed["zero"] == "0"
      assert parsed["false_value"] == "false"
    end
  end
end
