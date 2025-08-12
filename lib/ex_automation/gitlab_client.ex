defmodule ExAutomation.GitlabClient do
  @moduledoc """
  GitLab API client for interacting with GitLab projects and releases.
  """

  require Logger

  @base_url "https://gitlab.com/api/v4"

  @doc """
  Lists releases for a given GitLab project.

  ## Parameters

    * `project_id` - The project ID or path (e.g., "group/project" or numeric ID)
    * `token` - GitLab API token for authentication
    * `opts` - Optional parameters (keyword list)

  ## Options

    * `:base_url` - Custom GitLab instance URL (defaults to gitlab.com)
    * `:per_page` - Number of releases per page (default: 20, max: 100)
    * `:page` - Page number to retrieve (default: 1)
    * `:sort` - Sort order: "asc" or "desc" (default: "desc")
    * `:order_by` - Order by: "created_at" or "released_at" (default: "created_at")

  ## Examples

      iex> ExAutomation.GitlabClient.list_releases("my-group/my-project", "glpat-xxxxxxxxxxxx")
      {:ok, [%{"name" => "v1.0.0", "tag_name" => "v1.0.0", ...}, ...]}

      iex> ExAutomation.GitlabClient.list_releases("123", "glpat-xxxxxxxxxxxx", per_page: 10)
      {:ok, [%{"name" => "v1.0.0", ...}, ...]}

      iex> ExAutomation.GitlabClient.list_releases("invalid/project", "invalid-token")
      {:error, %{status: 404, body: %{"message" => "404 Project Not Found"}}}

  """
  @spec list_releases(String.t(), String.t(), keyword()) ::
          {:ok, list(map())} | {:error, map()}
  def list_releases(project_id, token, opts \\ []) do
    base_url = Keyword.get(opts, :base_url, @base_url)
    per_page = Keyword.get(opts, :per_page, 20)
    page = Keyword.get(opts, :page, 1)
    sort = Keyword.get(opts, :sort, "desc")
    order_by = Keyword.get(opts, :order_by, "created_at")

    # URL encode the project_id to handle paths with special characters
    encoded_project_id = URI.encode_www_form(project_id)

    url = "#{base_url}/projects/#{encoded_project_id}/releases"

    query_params = [
      per_page: per_page,
      page: page,
      sort: sort,
      order_by: order_by
    ]

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    Logger.debug("GitLab API request: GET #{url}")

    case Req.get(url, headers: headers, params: query_params) do
      {:ok, response} ->
        case response.status do
          200 ->
            {:ok, response.body}

          status when status in [401, 403] ->
            {:error, %{status: status, body: response.body, message: "Authentication failed"}}

          404 ->
            {:error, %{status: 404, body: response.body, message: "Project not found"}}

          status when status >= 400 ->
            {:error, %{status: status, body: response.body, message: "API request failed"}}
        end

      {:error, exception} ->
        Logger.error("GitLab API request failed: #{inspect(exception)}")
        {:error, %{message: "Network error", details: inspect(exception)}}
    end
  end
end
