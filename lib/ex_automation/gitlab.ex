defmodule ExAutomation.Gitlab do
  @moduledoc """
  The Gitlab context.
  """

  import Ecto.Query, warn: false
  alias ExAutomation.Gitlab.Release
  alias ExAutomation.Repo

  @doc """
  Subscribes to notifications about any release changes.

  The broadcasted messages match the pattern:

    * {:created, %Release{}}
    * {:updated, %Release{}}
    * {:deleted, %Release{}}

  """
  def subscribe_releases do
    Phoenix.PubSub.subscribe(ExAutomation.PubSub, "releases")
  end

  defp broadcast(message) do
    Phoenix.PubSub.broadcast(ExAutomation.PubSub, "releases", message)
  end

  @doc """
  Fetches releases from GitLab API for a given project.

  ## Parameters

    * `project_id` - The GitLab project ID
    * `token` - GitLab API token for authentication
    * `opts` - Optional parameters (default: [])

  ## Examples

      iex> list_releases(123, "valid -token")
      {:ok, [%{...}, ...]}

      iex> list_releases(123, "invalid_token")
      {:error, :unauthorized}

  """
  @spec list_releases(integer(), String.t(), keyword()) :: {:ok, list()} | {:error, atom()}
  defdelegate list_releases(project_id, token, opts \\ []), to: ExAutomation.Gitlab.Client

  @doc """
  Returns the list of releases.

  ## Examples

      iex> list_releases()
      [%Release{}, ...]

  """
  def list_releases do
    Repo.all(Release)
  end

  @doc """
  Returns the list of releases from a given year.

  ## Examples

      iex> list_releases_by_year(2024)
      [%Release{}, ...]

      iex> list_releases_by_year(2023)
      []

  """
  def list_releases_by_year(year) when is_integer(year) do
    start_date = NaiveDateTime.new!(year, 1, 1, 0, 0, 0)
    end_date = NaiveDateTime.new!(year, 12, 31, 23, 59, 59)

    from(r in Release,
      where: r.date >= ^start_date and r.date <= ^end_date,
      order_by: [desc: r.date]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single release.

  Raises `Ecto.NoResultsError` if the Release does not exist.

  ## Examples

      iex> get_release!(123)
      %Release{}

      iex> get_release!(456)
      ** (Ecto.NoResultsError)

  """
  def get_release!(id) do
    Repo.get_by!(Release, id: id)
  end

  @doc """
  Gets a single release by name.

  Raises `Ecto.NoResultsError` if the Release does not exist.

  ## Examples

      iex> get_release_by_name!("v1.0.0")
      %Release{}

      iex> get_release_by_name!("nonexistent-release")
      ** (Ecto.NoResultsError)

  """
  def get_release_by_name!(name) do
    Repo.get_by!(Release, name: name)
  end

  @doc """
  Creates a release.

  Note: Tags are not allowed during creation and will be ignored if provided.
  Use `update_release/2` to add tags after creation.

  ## Examples

      iex> create_release(%{name: "v1.0", date: ~N[2025-01-01 00:00:00], description: "Release"})
      {:ok, %Release{tags: []}}

      iex> create_release(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_release(attrs) do
    with {:ok, release = %Release{}} <-
           %Release{}
           |> Release.changeset(attrs)
           |> Repo.insert() do
      broadcast({:created, release})
      {:ok, release}
    end
  end

  @doc """
  Updates a release.

  This function allows updating all fields including tags.

  ## Examples

      iex> update_release(release, %{name: "new name"})
      {:ok, %Release{}}

      iex> update_release(release, %{tags: ["v1.0", "stable"]})
      {:ok, %Release{tags: ["v1.0", "stable"]}}

      iex> update_release(release, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_release(%Release{} = release, attrs) do
    with {:ok, release = %Release{}} <-
           release
           |> Release.update_changeset(attrs)
           |> Repo.update() do
      broadcast({:updated, release})
      {:ok, release}
    end
  end

  @doc """
  Deletes a release.

  ## Examples

      iex> delete_release(release)
      {:ok, %Release{}}

      iex> delete_release(release)
      {:error, %Ecto.Changeset{}}

  """
  def delete_release(%Release{} = release) do
    with {:ok, release = %Release{}} <-
           Repo.delete(release) do
      broadcast({:deleted, release})
      {:ok, release}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking release changes.

  Uses the update changeset which allows modification of all fields including tags.

  ## Examples

      iex> change_release(release)
      %Ecto.Changeset{data: %Release{}}

      iex> change_release(release, %{tags: ["new", "tags"]})
      %Ecto.Changeset{changes: %{tags: ["new", "tags"]}}

  """
  def change_release(%Release{} = release, attrs \\ %{}) do
    Release.update_changeset(release, attrs)
  end
end
