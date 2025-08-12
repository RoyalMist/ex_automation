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

    attrs =
      Enum.into(attrs, %{
        date: ~N[2025-08-11 08:34:00],
        description: "some description",
        name: "some name #{unique_id}"
      })

    {:ok, release} = ExAutomation.Gitlab.create_release(attrs)
    release
  end
end
