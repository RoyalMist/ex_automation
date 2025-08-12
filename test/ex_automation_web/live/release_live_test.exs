defmodule ExAutomationWeb.ReleaseLiveTest do
  use ExAutomationWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExAutomation.GitlabFixtures

  @create_attrs %{name: "some name", date: "2025-08-11T08:34:00", description: "some description"}
  @update_attrs %{
    name: "some updated name",
    date: "2025-08-12T08:34:00",
    description: "some updated description"
  }
  @invalid_attrs %{name: nil, date: nil, description: nil}

  setup :register_and_log_in_user

  defp create_release(%{scope: scope}) do
    release = release_fixture(scope)

    %{release: release}
  end

  describe "Index" do
    setup [:create_release]

    test "lists all releases", %{conn: conn, release: release} do
      {:ok, _index_live, html} = live(conn, ~p"/releases")

      assert html =~ "Listing Releases"
      assert html =~ release.name
    end

    test "saves new release", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/releases")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Release")
               |> render_click()
               |> follow_redirect(conn, ~p"/releases/new")

      assert render(form_live) =~ "New Release"

      assert form_live
             |> form("#release-form", release: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#release-form", release: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/releases")

      html = render(index_live)
      assert html =~ "Release created successfully"
      assert html =~ "some name"
    end

    test "updates release in listing", %{conn: conn, release: release} do
      {:ok, index_live, _html} = live(conn, ~p"/releases")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#releases-#{release.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/releases/#{release}/edit")

      assert render(form_live) =~ "Edit Release"

      assert form_live
             |> form("#release-form", release: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#release-form", release: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/releases")

      html = render(index_live)
      assert html =~ "Release updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes release in listing", %{conn: conn, release: release} do
      {:ok, index_live, _html} = live(conn, ~p"/releases")

      assert index_live |> element("#releases-#{release.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#releases-#{release.id}")
    end
  end

  describe "Show" do
    setup [:create_release]

    test "displays release", %{conn: conn, release: release} do
      {:ok, _show_live, html} = live(conn, ~p"/releases/#{release}")

      assert html =~ "Show Release"
      assert html =~ release.name
    end

    test "updates release and returns to show", %{conn: conn, release: release} do
      {:ok, show_live, _html} = live(conn, ~p"/releases/#{release}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/releases/#{release}/edit?return_to=show")

      assert render(form_live) =~ "Edit Release"

      assert form_live
             |> form("#release-form", release: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#release-form", release: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/releases/#{release}")

      html = render(show_live)
      assert html =~ "Release updated successfully"
      assert html =~ "some updated name"
    end
  end
end
