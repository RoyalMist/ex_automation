defmodule ExAutomationWeb.IssueLiveTest do
  use ExAutomationWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExAutomation.JiraFixtures

  @create_attrs %{status: "some status", type: "some type", key: "some key", parent_key: "some parent_key", summary: "some summary"}
  @update_attrs %{status: "some updated status", type: "some updated type", key: "some updated key", parent_key: "some updated parent_key", summary: "some updated summary"}
  @invalid_attrs %{status: nil, type: nil, key: nil, parent_key: nil, summary: nil}

  setup :register_and_log_in_user

  defp create_issue(%{scope: scope}) do
    issue = issue_fixture(scope)

    %{issue: issue}
  end

  describe "Index" do
    setup [:create_issue]

    test "lists all issues", %{conn: conn, issue: issue} do
      {:ok, _index_live, html} = live(conn, ~p"/issues")

      assert html =~ "Listing Issues"
      assert html =~ issue.key
    end

    test "saves new issue", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/issues")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Issue")
               |> render_click()
               |> follow_redirect(conn, ~p"/issues/new")

      assert render(form_live) =~ "New Issue"

      assert form_live
             |> form("#issue-form", issue: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#issue-form", issue: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/issues")

      html = render(index_live)
      assert html =~ "Issue created successfully"
      assert html =~ "some key"
    end

    test "updates issue in listing", %{conn: conn, issue: issue} do
      {:ok, index_live, _html} = live(conn, ~p"/issues")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#issues-#{issue.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/issues/#{issue}/edit")

      assert render(form_live) =~ "Edit Issue"

      assert form_live
             |> form("#issue-form", issue: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#issue-form", issue: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/issues")

      html = render(index_live)
      assert html =~ "Issue updated successfully"
      assert html =~ "some updated key"
    end

    test "deletes issue in listing", %{conn: conn, issue: issue} do
      {:ok, index_live, _html} = live(conn, ~p"/issues")

      assert index_live |> element("#issues-#{issue.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#issues-#{issue.id}")
    end
  end

  describe "Show" do
    setup [:create_issue]

    test "displays issue", %{conn: conn, issue: issue} do
      {:ok, _show_live, html} = live(conn, ~p"/issues/#{issue}")

      assert html =~ "Show Issue"
      assert html =~ issue.key
    end

    test "updates issue and returns to show", %{conn: conn, issue: issue} do
      {:ok, show_live, _html} = live(conn, ~p"/issues/#{issue}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/issues/#{issue}/edit?return_to=show")

      assert render(form_live) =~ "Edit Issue"

      assert form_live
             |> form("#issue-form", issue: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#issue-form", issue: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/issues/#{issue}")

      html = render(show_live)
      assert html =~ "Issue updated successfully"
      assert html =~ "some updated key"
    end
  end
end
