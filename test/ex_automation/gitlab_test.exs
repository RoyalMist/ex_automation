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

    test "get_release_by_name!/1 returns the release with given name" do
      release = release_fixture()
      assert Gitlab.get_release_by_name!(release.name) == release
    end

    test "get_release_by_name!/1 raises when release does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Gitlab.get_release_by_name!("nonexistent-release")
      end
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

    test "get_release!/1 raises when release does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Gitlab.get_release!(999_999)
      end
    end

    test "update_release/2 with duplicate name returns error changeset" do
      release1 = release_fixture()
      release2 = release_fixture()

      duplicate_attrs = %{name: release1.name}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Gitlab.update_release(release2, duplicate_attrs)

      assert "has already been taken" in errors_on(changeset).name
    end

    test "change_release/1 with attributes returns changeset with changes" do
      release = release_fixture()
      attrs = %{name: "new name", description: "new description"}
      changeset = Gitlab.change_release(release, attrs)

      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.name == "new name"
      assert changeset.changes.description == "new description"
    end

    test "list_releases/0 returns empty list when no releases exist" do
      # Clean up any existing releases first
      Gitlab.list_releases()
      |> Enum.each(&Gitlab.delete_release/1)

      assert Gitlab.list_releases() == []
    end

    test "subscribe_releases/0 allows subscription to release notifications" do
      # Test that we can subscribe without errors
      assert :ok = Gitlab.subscribe_releases()
    end

    test "create_release/1 broadcasts created message" do
      Gitlab.subscribe_releases()

      valid_attrs = %{
        name: "broadcast test release",
        date: ~N[2025-08-11 08:34:00],
        description: "test description"
      }

      {:ok, release} = Gitlab.create_release(valid_attrs)

      assert_receive {:created, ^release}
    end

    test "update_release/2 broadcasts updated message" do
      Gitlab.subscribe_releases()
      release = release_fixture()

      update_attrs = %{name: "updated broadcast test"}
      {:ok, updated_release} = Gitlab.update_release(release, update_attrs)

      assert_receive {:updated, ^updated_release}
    end

    test "delete_release/1 broadcasts deleted message" do
      Gitlab.subscribe_releases()
      release = release_fixture()

      {:ok, deleted_release} = Gitlab.delete_release(release)

      assert_receive {:deleted, ^deleted_release}
    end

    test "changeset validation requires name" do
      attrs = %{date: ~N[2025-08-11 08:34:00], description: "some description"}
      changeset = Release.changeset(%Release{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "changeset validation requires date" do
      attrs = %{name: "some name", description: "some description"}
      changeset = Release.changeset(%Release{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).date
    end

    test "changeset validation requires description" do
      attrs = %{name: "some name", date: ~N[2025-08-11 08:34:00]}
      changeset = Release.changeset(%Release{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).description
    end

    test "changeset is valid with all required fields" do
      attrs = %{
        name: "valid release",
        date: ~N[2025-08-11 08:34:00],
        description: "valid description"
      }

      changeset = Release.changeset(%Release{}, attrs)

      assert changeset.valid?
    end

    test "timestamps are set correctly on creation" do
      valid_attrs = %{
        name: "timestamp test release",
        date: ~N[2025-08-11 08:34:00],
        description: "test description"
      }

      {:ok, release} = Gitlab.create_release(valid_attrs)

      assert %DateTime{} = release.inserted_at
      assert %DateTime{} = release.updated_at
      assert release.inserted_at == release.updated_at
    end
  end
end
