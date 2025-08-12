defmodule ExAutomationWeb.ReleaseLiveTest do
  use ExAutomationWeb.ConnCase
  import Phoenix.LiveViewTest
  import ExAutomation.GitlabFixtures

  setup :register_and_log_in_user

  defp create_release(_) do
    release = release_fixture()
    %{release: release}
  end

  describe "Index" do
    setup [:create_release]

    test "lists all releases", %{conn: conn, release: release} do
      {:ok, _index_live, html} = live(conn, ~p"/releases")

      assert html =~ "Listing Releases"
      assert html =~ release.name
    end
  end

  describe "Show" do
    setup [:create_release]

    test "displays release", %{conn: conn, release: release} do
      {:ok, _show_live, html} = live(conn, ~p"/releases/#{release}")

      assert html =~ "Show Release"
      assert html =~ release.name
    end
  end
end
