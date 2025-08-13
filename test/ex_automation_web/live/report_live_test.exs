defmodule ExAutomationWeb.ReportLiveTest do
  use ExAutomationWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExAutomation.ReportingFixtures

  @create_attrs %{name: "some name", year: 42}
  @invalid_attrs %{name: nil, year: nil}

  setup :register_and_log_in_user

  defp create_report(%{scope: scope}) do
    report = report_fixture(scope)

    %{report: report}
  end

  describe "Index" do
    setup [:create_report]

    test "lists all reports", %{conn: conn, report: report} do
      {:ok, _index_live, html} = live(conn, ~p"/reports")

      assert html =~ "Listing Reports"
      assert html =~ report.name
    end

    test "saves new report", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/reports")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Report")
               |> render_click()
               |> follow_redirect(conn, ~p"/reports/new")

      assert render(form_live) =~ "New Report"

      assert form_live
             |> form("#report-form", report: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#report-form", report: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/reports")

      html = render(index_live)
      assert html =~ "Report created successfully"
      assert html =~ "some name"
    end

    test "deletes report in listing", %{conn: conn, report: report} do
      {:ok, index_live, _html} = live(conn, ~p"/reports")

      assert index_live |> element("#reports-#{report.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#reports-#{report.id}")
    end
  end

  describe "Show" do
    setup [:create_report]

    test "displays report", %{conn: conn, report: report} do
      {:ok, _show_live, html} = live(conn, ~p"/reports/#{report}")

      assert html =~ "Show Report"
      assert html =~ report.name
    end
  end
end
