defmodule ExAutomation.Jira.Issue do
  use Ecto.Schema
  import Ecto.Changeset

  schema "issues" do
    field :key, :string
    field :summary, :string
    field :status, :string
    field :type, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(issue, attrs) do
    issue
    |> cast(attrs, [:key, :summary, :status, :type])
    |> validate_required([:key, :summary, :status, :type])
    |> unique_constraint(:key)
  end
end
