defmodule ExAutomation.Jira.Issue do
  @moduledoc """
  Schema for Jira issues with hierarchical parent-child relationships.

  Issues can have a parent-child relationship where:
  - A parent issue can have multiple children
  - A child issue can have only one parent
  - Root issues have no parent (parent_id is nil)
  - When a parent is deleted, children become orphaned (parent_id is set to nil)

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
        parent_id: epic.id
      })

  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "issues" do
    field :key, :string
    field :summary, :string
    field :status, :string
    field :type, :string

    # Self-referencing association for hierarchical structure
    belongs_to :parent, __MODULE__, foreign_key: :parent_id
    has_many :children, __MODULE__, foreign_key: :parent_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating and updating issues.

  Supports hierarchical relationships through the optional `parent_id` field.
  When `parent_id` is provided, it must reference an existing issue.

  ## Required fields
  - `:key` - Unique identifier for the issue
  - `:summary` - Brief description of the issue
  - `:status` - Current status (e.g., "To Do", "In Progress", "Done")
  - `:type` - Issue type (e.g., "Epic", "Story", "Task", "Bug")

  ## Optional fields
  - `:parent_id` - Reference to parent issue (nil for root issues)
  """
  def changeset(issue, attrs) do
    issue
    |> cast(attrs, [:key, :summary, :status, :type, :parent_id])
    |> validate_required([:key, :summary, :status, :type])
    |> unique_constraint(:key)
    |> foreign_key_constraint(:parent_id)
  end
end
