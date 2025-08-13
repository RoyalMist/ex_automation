defmodule ExAutomationWeb.EntryLiveTest do
  use ExAutomationWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExAutomation.ReportingFixtures

  @create_attrs %{
    release_name: "some release_name",
    release_date: "2025-08-12T12:26:00",
    issue_key: "some issue_key",
    issue_summary: "some issue_summary",
    issue_type: "some issue_type",
    issue_status: "some issue_status",
    initiative_key: "some initiative_key",
    initiative_summary: "some initiative_summary"
  }

  @invalid_attrs %{
    release_name: nil,
    release_date: nil,
    issue_key: nil,
    issue_summary: nil,
    issue_type: nil,
    issue_status: nil,
    initiative_key: nil,
    initiative_summary: nil
  }

  setup :register_and_log_in_user

  defp create_entry(%{scope: scope}) do
    entry = entry_fixture(scope)

    %{entry: entry}
  end

  describe "Index" do
    setup [:create_entry]

    test "lists all entries", %{conn: conn, entry: entry} do
      {:ok, _index_live, html} = live(conn, ~p"/entries")

      assert html =~ "Listing Entries"
      assert html =~ entry.release_name
    end

    test "saves new entry", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/entries")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Entry")
               |> render_click()
               |> follow_redirect(conn, ~p"/entries/new")

      assert render(form_live) =~ "New Entry"

      assert form_live
             |> form("#entry-form", entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#entry-form", entry: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/entries")

      html = render(index_live)
      assert html =~ "Entry created successfully"
      assert html =~ "some release_name"
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
