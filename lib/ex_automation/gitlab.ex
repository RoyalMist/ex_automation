defmodule ExAutomation.Gitlab do
  @moduledoc """
  The Gitlab context.
  """

  import Ecto.Query, warn: false
  alias ExAutomation.Repo

  alias ExAutomation.Gitlab.Release
  alias ExAutomation.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any release changes.

  The broadcasted messages match the pattern:

    * {:created, %Release{}}
    * {:updated, %Release{}}
    * {:deleted, %Release{}}

  """
  def subscribe_releases(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(ExAutomation.PubSub, "user:#{key}:releases")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(ExAutomation.PubSub, "user:#{key}:releases", message)
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

      iex> list_releases(scope)
      [%Release{}, ...]

  """
  def list_releases(%Scope{} = scope) do
    Repo.all_by(Release, user_id: scope.user.id)
  end

  @doc """
  Gets a single release.

  Raises `Ecto.NoResultsError` if the Release does not exist.

  ## Examples

      iex> get_release!(scope, 123)
      %Release{}

      iex> get_release!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_release!(%Scope{} = scope, id) do
    Repo.get_by!(Release, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a release.

  ## Examples

      iex> create_release(scope, %{field: value})
      {:ok, %Release{}}

      iex> create_release(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_release(%Scope{} = scope, attrs) do
    with {:ok, release = %Release{}} <-
           %Release{}
           |> Release.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, release})
      {:ok, release}
    end
  end

  @doc """
  Updates a release.

  ## Examples

      iex> update_release(scope, release, %{field: new_value})
      {:ok, %Release{}}

      iex> update_release(scope, release, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_release(%Scope{} = scope, %Release{} = release, attrs) do
    true = release.user_id == scope.user.id

    with {:ok, release = %Release{}} <-
           release
           |> Release.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, release})
      {:ok, release}
    end
  end

  @doc """
  Deletes a release.

  ## Examples

      iex> delete_release(scope, release)
      {:ok, %Release{}}

      iex> delete_release(scope, release)
      {:error, %Ecto.Changeset{}}

  """
  def delete_release(%Scope{} = scope, %Release{} = release) do
    true = release.user_id == scope.user.id

    with {:ok, release = %Release{}} <-
           Repo.delete(release) do
      broadcast(scope, {:deleted, release})
      {:ok, release}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking release changes.

  ## Examples

      iex> change_release(scope, release)
      %Ecto.Changeset{data: %Release{}}

  """
  def change_release(%Scope{} = scope, %Release{} = release, attrs \\ %{}) do
    true = release.user_id == scope.user.id

    Release.changeset(release, attrs, scope)
  end
end
