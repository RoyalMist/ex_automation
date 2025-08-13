defmodule ExAutomationWeb.EntryLiveTest do
  use ExAutomationWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExAutomation.ReportingFixtures

  setup :register_and_log_in_user

  defp create_entry(%{scope: scope}) do
    report = report_fixture(scope)
    entry = entry_fixture(scope, %{report_id: report.id})

    %{entry: entry, report: report}
  end

  describe "Index" do
    setup [:create_entry]

    test "lists all entries", %{conn: conn, entry: entry} do
      {:ok, _index_live, html} = live(conn, ~p"/entries")

      assert html =~ "Listing Entries"
      assert html =~ entry.release_name
    end
  end

  describe "Show" do
    setup [:create_entry]

    test "displays entry", %{conn: conn, entry: entry} do
      {:ok, _show_live, html} = live(conn, ~p"/entries/#{entry}")

      assert html =~ "Show Entry"
      assert html =~ entry.release_name
    end
  end
end
