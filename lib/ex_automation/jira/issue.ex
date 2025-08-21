defmodule ExAutomation.Jira.Issue do
  @moduledoc """
  Schema for Jira issues with hierarchical parent-child relationships.

  Issues can have a parent-child relationship where:
  - A parent issue can have multiple children
  - A child issue can have only one parent
  - Root issues have no parent (parent_key is nil)
  - When a parent is deleted, children become orphaned (parent_key is set to nil)

  ## Examples

      # Create a parent issue (epic)
      {:ok, epic} = create_issue(%{
        key: "EPIC-123",
        summary: "User Authentication",
        status: "In Progress",
        type: "Epic"
      })

      # Create child issues under the epic
      {:ok, story} = create_issue(%{
        key: "STORY-456",
        summary: "Login form",
        status: "To Do",
        type: "Story",
        parent_key: epic.key
      })

  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "issues" do
    field :key, :string
    field :summary, :string
    field :status, :string
    field :type, :string

    # Parent-child relationship using string keys
    field :parent_key, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating and updating issues.

  Supports hierarchical relationships through the optional `parent_key` field.
  When `parent_key` is provided, it must reference an existing issue's key.

  ## Required fields
  - `:key` - Unique identifier for the issue
  - `:summary` - Brief description of the issue
  - `:status` - Current status (e.g., "To Do", "In Progress", "Done")
  - `:type` - Issue type (e.g., "Epic", "Story", "Task", "Bug")

  ## Optional fields
  - `:parent_key` - Reference to parent issue key (nil for root issues)
  """
  def changeset(issue, attrs) do
    issue
    |> cast(attrs, [:key, :summary, :status, :type, :parent_key])
    |> validate_required([:key, :summary, :status, :type])
    |> unique_constraint(:key)
    |> validate_parent_key_exists()
  end

  defp validate_parent_key_exists(changeset) do
    case get_change(changeset, :parent_key) do
      nil ->
        changeset

      parent_key when parent_key != "" ->
        if parent_exists?(parent_key) do
          changeset
        else
          add_error(changeset, :parent_key, "does not exist")
        end

      _ ->
        changeset
    end
  end

  defp parent_exists?(parent_key) do
    import Ecto.Query
    ExAutomation.Repo.exists?(from i in __MODULE__, where: i.key == ^parent_key)
  end
end
