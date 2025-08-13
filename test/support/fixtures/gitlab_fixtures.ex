defmodule ExAutomation.GitlabFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExAutomation.Gitlab` context.
  """

  @doc """
  Generate a release.
  """
  def release_fixture(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    # Extract tags from attrs since they can't be set during creation
    {tags, create_attrs} = Map.pop(attrs, :tags)

    create_attrs =
      Enum.into(create_attrs, %{
        date: ~N[2025-08-11 08:34:00],
        description: "some description",
        name: "some name #{unique_id}"
      })

    {:ok, release} = ExAutomation.Gitlab.create_release(create_attrs)

    case tags do
      nil ->
        release

      tags ->
        {:ok, release} = ExAutomation.Gitlab.update_release(release, %{tags: tags})
        release
    end
  end
end
