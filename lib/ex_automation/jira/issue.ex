defmodule ExAutomation.Jira.Issue do
  use Ecto.Schema
  import Ecto.Changeset

  schema "issues" do
    field :key, :string
    field :parent_key, :string
    field :summary, :string
    field :status, :string
    field :type, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(issue, attrs) do
    issue
    |> cast(attrs, [:key, :parent_key, :summary, :status, :type])
    |> validate_required([:key, :parent_key, :summary, :status, :type])
  end
end
