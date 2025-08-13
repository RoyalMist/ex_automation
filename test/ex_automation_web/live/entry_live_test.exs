defmodule ExAutomationWeb.EntryLiveTest do
  use ExAutomationWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExAutomation.ReportingFixtures

  @create_attrs %{release_name: "some release_name", release_date: "2025-08-12T12:26:00", issue_key: "some issue_key", issue_summary: "some issue_summary", issue_type: "some issue_type", issue_status: "some issue_status", initiative_key: "some initiative_key", initiative_summary: "some initiative_summary"}
  @update_attrs %{release_name: "some updated release_name", release_date: "2025-08-13T12:26:00", issue_key: "some updated issue_key", issue_summary: "some updated issue_summary", issue_type: "some updated issue_type", issue_status: "some updated issue_status", initiative_key: "some updated initiative_key", initiative_summary: "some updated initiative_summary"}
  @invalid_attrs %{release_name: nil, release_date: nil, issue_key: nil, issue_summary: nil, issue_type: nil, issue_status: nil, initiative_key: nil, initiative_summary: nil}

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

    test "updates entry in listing", %{conn: conn, entry: entry} do
      {:ok, index_live, _html} = live(conn, ~p"/entries")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#entries-#{entry.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/entries/#{entry}/edit")

      assert render(form_live) =~ "Edit Entry"

      assert form_live
             |> form("#entry-form", entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#entry-form", entry: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/entries")

      html = render(index_live)
      assert html =~ "Entry updated successfully"
      assert html =~ "some updated release_name"
    end

    test "deletes entry in listing", %{conn: conn, entry: entry} do
      {:ok, index_live, _html} = live(conn, ~p"/entries")

      assert index_live |> element("#entries-#{entry.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#entries-#{entry.id}")
    end
  end

  describe "Show" do
    setup [:create_entry]

    test "displays entry", %{conn: conn, entry: entry} do
      {:ok, _show_live, html} = live(conn, ~p"/entries/#{entry}")

      assert html =~ "Show Entry"
      assert html =~ entry.release_name
    end

    test "updates entry and returns to show", %{conn: conn, entry: entry} do
      {:ok, show_live, _html} = live(conn, ~p"/entries/#{entry}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/entries/#{entry}/edit?return_to=show")

      assert render(form_live) =~ "Edit Entry"

      assert form_live
             |> form("#entry-form", entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#entry-form", entry: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/entries/#{entry}")

      html = render(show_live)
      assert html =~ "Entry updated successfully"
      assert html =~ "some updated release_name"
    end
  end
end
