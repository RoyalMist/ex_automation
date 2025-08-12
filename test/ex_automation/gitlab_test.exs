defmodule ExAutomation.GitlabTest do
  use ExAutomation.DataCase
  alias ExAutomation.Gitlab

  describe "releases" do
    alias ExAutomation.Gitlab.Release

    import ExAutomation.GitlabFixtures

    @invalid_attrs %{name: nil, date: nil, description: nil}

    test "list_releases/0 returns all releases" do
      release = release_fixture()
      other_release = release_fixture()
      releases = Gitlab.list_releases()
      assert release in releases
      assert other_release in releases
    end

    test "get_release!/1 returns the release with given id" do
      release = release_fixture()
      assert Gitlab.get_release!(release.id) == release
    end

    test "create_release/1 with valid data creates a release" do
      valid_attrs = %{
        name: "some name",
        date: ~N[2025-08-11 08:34:00],
        description: "some description"
      }

      assert {:ok, %Release{} = release} = Gitlab.create_release(valid_attrs)
      assert release.name == "some name"
      assert release.date == ~N[2025-08-11 08:34:00]
      assert release.description == "some description"
    end

    test "create_release/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gitlab.create_release(@invalid_attrs)
    end

    test "update_release/2 with valid data updates the release" do
      release = release_fixture()

      update_attrs = %{
        name: "some updated name",
        date: ~N[2025-08-12 08:34:00],
        description: "some updated description"
      }

      assert {:ok, %Release{} = release} = Gitlab.update_release(release, update_attrs)
      assert release.name == "some updated name"
      assert release.date == ~N[2025-08-12 08:34:00]
      assert release.description == "some updated description"
    end

    test "update_release/2 with invalid data returns error changeset" do
      release = release_fixture()
      assert {:error, %Ecto.Changeset{}} = Gitlab.update_release(release, @invalid_attrs)
      assert release == Gitlab.get_release!(release.id)
    end

    test "delete_release/1 deletes the release" do
      release = release_fixture()
      assert {:ok, %Release{}} = Gitlab.delete_release(release)
      assert_raise Ecto.NoResultsError, fn -> Gitlab.get_release!(release.id) end
    end

    test "change_release/1 returns a release changeset" do
      release = release_fixture()
      assert %Ecto.Changeset{} = Gitlab.change_release(release)
    end

    test "create_release/1 with duplicate name returns error changeset" do
      release = release_fixture()

      duplicate_attrs = %{
        name: release.name,
        date: ~N[2025-08-12 08:34:00],
        description: "another description"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Gitlab.create_release(duplicate_attrs)
      assert "has already been taken" in errors_on(changeset).name
    end
  end
end
