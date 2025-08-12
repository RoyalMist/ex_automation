defmodule ExAutomation.Gitlab do
  @moduledoc """
  The Gitlab context.
  """

  import Ecto.Query, warn: false
  alias ExAutomation.Repo
  alias ExAutomation.Gitlab.Release

  @doc """
  Subscribes to notifications about any release changes.

  The broadcasted messages match the pattern:

    * {:created, %Release{}}
    * {:updated, %Release{}}
    * {:deleted, %Release{}}

  """
  def subscribe_releases() do
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

      iex> list_releases(123, "glpat-xxxxxxxxxxxxxxxxxxxx")
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
  def list_releases() do
    Repo.all(Release)
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

  ## Examples

      iex> create_release(%{field: value})
      {:ok, %Release{}}

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

  ## Examples

      iex> update_release(release, %{field: new_value})
      {:ok, %Release{}}

      iex> update_release(release, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_release(%Release{} = release, attrs) do
    with {:ok, release = %Release{}} <-
           release
           |> Release.changeset(attrs)
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

  ## Examples

      iex> change_release(release)
      %Ecto.Changeset{data: %Release{}}

  """
  def change_release(%Release{} = release, attrs \\ %{}) do
    Release.changeset(release, attrs)
  end
end
