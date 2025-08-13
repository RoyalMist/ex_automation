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
      assert release.tags == []
    end

    test "create_release/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gitlab.create_release(@invalid_attrs)
    end

    test "update_release/2 with valid data updates the release" do
      release = release_fixture()

      update_attrs = %{
        name: "some updated name",
        date: ~N[2025-08-12 08:34:00],
        description: "some updated description",
        tags: ["v2.0", "updated"]
      }

      assert {:ok, %Release{} = release} = Gitlab.update_release(release, update_attrs)
      assert release.name == "some updated name"
      assert release.date == ~N[2025-08-12 08:34:00]
      assert release.description == "some updated description"
      assert release.tags == ["v2.0", "updated"]
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

    test "create_release/1 without tags field defaults to empty array" do
      valid_attrs = %{
        name: "no tags release",
        date: ~N[2025-08-11 08:34:00],
        description: "test description"
      }

      assert {:ok, %Release{} = release} = Gitlab.create_release(valid_attrs)
      assert release.tags == []
    end

    test "create_release/1 ignores tags field" do
      valid_attrs = %{
        name: "tags ignored release",
        date: ~N[2025-08-11 08:34:00],
        description: "test description",
        tags: ["should", "be", "ignored"]
      }

      assert {:ok, %Release{} = release} = Gitlab.create_release(valid_attrs)
      assert release.tags == []
    end

    test "update_release/2 can update tags" do
      release = release_fixture()
      update_attrs = %{tags: ["new", "tags", "array"]}

      assert {:ok, %Release{} = updated_release} = Gitlab.update_release(release, update_attrs)
      assert updated_release.tags == ["new", "tags", "array"]
    end

    test "update_release/2 can clear tags" do
      release = release_fixture(%{tags: ["existing", "tags"]})
      update_attrs = %{tags: []}

      assert {:ok, %Release{} = updated_release} = Gitlab.update_release(release, update_attrs)
      assert updated_release.tags == []
    end

    test "update_changeset accepts valid tags array" do
      attrs = %{
        name: "valid release",
        date: ~N[2025-08-11 08:34:00],
        description: "valid description",
        tags: ["tag1", "tag2", "tag3"]
      }

      changeset = Release.update_changeset(%Release{}, attrs)

      assert changeset.valid?
      assert changeset.changes.tags == ["tag1", "tag2", "tag3"]
    end

    test "update_changeset accepts empty tags array" do
      attrs = %{
        name: "valid release",
        date: ~N[2025-08-11 08:34:00],
        description: "valid description",
        tags: []
      }

      changeset = Release.update_changeset(%Release{}, attrs)

      assert changeset.valid?
      # Empty array is not considered a change if the default is also empty
      # So we check that tags field exists and is empty in the data
      assert Map.get(changeset.changes, :tags, []) == []
    end

    test "update_changeset handles nil tags gracefully" do
      attrs = %{
        name: "valid release",
        date: ~N[2025-08-11 08:34:00],
        description: "valid description",
        tags: nil
      }

      changeset = Release.update_changeset(%Release{}, attrs)

      assert changeset.valid?
      # nil tags should be cast and will appear in changes
      assert changeset.changes.tags == nil
    end

    test "update_changeset validates tags as list of strings" do
      attrs = %{
        name: "valid release",
        date: ~N[2025-08-11 08:34:00],
        description: "valid description",
        tags: ["string1", "string2", "string3"]
      }

      changeset = Release.update_changeset(%Release{}, attrs)

      assert changeset.valid?
      assert changeset.changes.tags == ["string1", "string2", "string3"]
    end

    test "update_release/2 handles duplicate tags" do
      release = release_fixture()
      update_attrs = %{tags: ["tag1", "tag1", "tag2", "tag2"]}

      assert {:ok, %Release{} = updated_release} = Gitlab.update_release(release, update_attrs)
      # Should preserve duplicates as provided
      assert updated_release.tags == ["tag1", "tag1", "tag2", "tag2"]
    end

    test "update_release/2 handles very long tags array" do
      release = release_fixture()
      long_tags = Enum.map(1..100, fn i -> "tag#{i}" end)
      update_attrs = %{tags: long_tags}

      assert {:ok, %Release{} = updated_release} = Gitlab.update_release(release, update_attrs)
      assert length(updated_release.tags) == 100
      assert "tag1" in updated_release.tags
      assert "tag100" in updated_release.tags
    end

    test "update_release/2 preserves other fields when updating tags" do
      release =
        release_fixture(%{
          name: "original name",
          description: "original description",
          tags: ["original", "tags"]
        })

      update_attrs = %{tags: ["new", "tags"]}

      assert {:ok, %Release{} = updated_release} = Gitlab.update_release(release, update_attrs)
      assert updated_release.tags == ["new", "tags"]
      assert updated_release.name == "original name"
      assert updated_release.description == "original description"
      assert updated_release.date == release.date
    end

    test "changeset/2 for creation does not cast tags field" do
      attrs = %{
        name: "valid release",
        date: ~N[2025-08-11 08:34:00],
        description: "valid description",
        tags: ["should", "be", "ignored"]
      }

      changeset = Release.changeset(%Release{}, attrs)

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :tags)
    end

    test "update_changeset/2 for updates casts tags field" do
      attrs = %{
        name: "valid release",
        date: ~N[2025-08-11 08:34:00],
        description: "valid description",
        tags: ["tag1", "tag2"]
      }

      changeset = Release.update_changeset(%Release{}, attrs)

      assert changeset.valid?
      assert changeset.changes.tags == ["tag1", "tag2"]
    end

    test "changeset/2 validation requires name" do
      attrs = %{date: ~N[2025-08-11 08:34:00], description: "some description"}
      changeset = Release.changeset(%Release{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "changeset/2 validation requires date" do
      attrs = %{name: "some name", description: "some description"}
      changeset = Release.changeset(%Release{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).date
    end

    test "changeset/2 validation requires description" do
      attrs = %{name: "some name", date: ~N[2025-08-11 08:34:00]}
      changeset = Release.changeset(%Release{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).description
    end

    test "changeset/2 is valid with all required fields" do
      attrs = %{
        name: "valid release",
        date: ~N[2025-08-11 08:34:00],
        description: "valid description"
      }

      changeset = Release.changeset(%Release{}, attrs)

      assert changeset.valid?
    end

    test "update_changeset/2 validation requires name" do
      attrs = %{date: ~N[2025-08-11 08:34:00], description: "some description"}
      changeset = Release.update_changeset(%Release{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "update_changeset/2 validation requires date" do
      attrs = %{name: "some name", description: "some description"}
      changeset = Release.update_changeset(%Release{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).date
    end

    test "update_changeset/2 validation requires description" do
      attrs = %{name: "some name", date: ~N[2025-08-11 08:34:00]}
      changeset = Release.update_changeset(%Release{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).description
    end

    test "update_changeset/2 is valid with all required fields" do
      attrs = %{
        name: "valid release",
        date: ~N[2025-08-11 08:34:00],
        description: "valid description"
      }

      changeset = Release.update_changeset(%Release{}, attrs)

      assert changeset.valid?
    end

    test "list_releases_by_year/1 returns releases from specific year" do
      # Create releases from different years
      release_2023 =
        release_fixture(%{
          name: "release 2023",
          date: ~N[2023-06-15 12:00:00],
          description: "Release from 2023"
        })

      release_2024_jan =
        release_fixture(%{
          name: "release 2024 jan",
          date: ~N[2024-01-01 00:00:00],
          description: "Release from January 2024"
        })

      release_2024_dec =
        release_fixture(%{
          name: "release 2024 dec",
          date: ~N[2024-12-31 23:59:59],
          description: "Release from December 2024"
        })

      release_2025 =
        release_fixture(%{
          name: "release 2025",
          date: ~N[2025-03-10 15:30:00],
          description: "Release from 2025"
        })

      # Test 2024 releases
      releases_2024 = Gitlab.list_releases_by_year(2024)
      assert length(releases_2024) == 2
      assert release_2024_dec in releases_2024
      assert release_2024_jan in releases_2024
      refute release_2023 in releases_2024
      refute release_2025 in releases_2024

      # Verify ordering (desc by date)
      assert releases_2024 == [release_2024_dec, release_2024_jan]

      # Test 2023 releases
      releases_2023 = Gitlab.list_releases_by_year(2023)
      assert length(releases_2023) == 1
      assert release_2023 in releases_2023

      # Test year with no releases
      releases_2022 = Gitlab.list_releases_by_year(2022)
      assert releases_2022 == []
    end
  end
end
