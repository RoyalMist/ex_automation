defmodule ExAutomation.GitlabTest do
  use ExAutomation.DataCase

  alias ExAutomation.Gitlab

  describe "releases" do
    alias ExAutomation.Gitlab.Release

    import ExAutomation.AccountsFixtures, only: [user_scope_fixture: 0]
    import ExAutomation.GitlabFixtures

    @invalid_attrs %{name: nil, date: nil, description: nil}

    test "list_releases/1 returns all scoped releases" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      release = release_fixture(scope)
      other_release = release_fixture(other_scope)
      assert Gitlab.list_releases(scope) == [release]
      assert Gitlab.list_releases(other_scope) == [other_release]
    end

    test "get_release!/2 returns the release with given id" do
      scope = user_scope_fixture()
      release = release_fixture(scope)
      other_scope = user_scope_fixture()
      assert Gitlab.get_release!(scope, release.id) == release
      assert_raise Ecto.NoResultsError, fn -> Gitlab.get_release!(other_scope, release.id) end
    end

    test "create_release/2 with valid data creates a release" do
      valid_attrs = %{
        name: "some name",
        date: ~N[2025-08-11 08:34:00],
        description: "some description"
      }

      scope = user_scope_fixture()

      assert {:ok, %Release{} = release} = Gitlab.create_release(scope, valid_attrs)
      assert release.name == "some name"
      assert release.date == ~N[2025-08-11 08:34:00]
      assert release.description == "some description"
      assert release.user_id == scope.user.id
    end

    test "create_release/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Gitlab.create_release(scope, @invalid_attrs)
    end

    test "update_release/3 with valid data updates the release" do
      scope = user_scope_fixture()
      release = release_fixture(scope)

      update_attrs = %{
        name: "some updated name",
        date: ~N[2025-08-12 08:34:00],
        description: "some updated description"
      }

      assert {:ok, %Release{} = release} = Gitlab.update_release(scope, release, update_attrs)
      assert release.name == "some updated name"
      assert release.date == ~N[2025-08-12 08:34:00]
      assert release.description == "some updated description"
    end

    test "update_release/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      release = release_fixture(scope)

      assert_raise MatchError, fn ->
        Gitlab.update_release(other_scope, release, %{})
      end
    end

    test "update_release/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      release = release_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Gitlab.update_release(scope, release, @invalid_attrs)
      assert release == Gitlab.get_release!(scope, release.id)
    end

    test "delete_release/2 deletes the release" do
      scope = user_scope_fixture()
      release = release_fixture(scope)
      assert {:ok, %Release{}} = Gitlab.delete_release(scope, release)
      assert_raise Ecto.NoResultsError, fn -> Gitlab.get_release!(scope, release.id) end
    end

    test "delete_release/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      release = release_fixture(scope)
      assert_raise MatchError, fn -> Gitlab.delete_release(other_scope, release) end
    end

    test "change_release/2 returns a release changeset" do
      scope = user_scope_fixture()
      release = release_fixture(scope)
      assert %Ecto.Changeset{} = Gitlab.change_release(scope, release)
    end
  end
end
