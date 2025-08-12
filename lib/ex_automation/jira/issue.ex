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
  def changeset(issue, attrs, user_scope) do
    issue
    |> cast(attrs, [:key, :parent_key, :summary, :status, :type])
    |> validate_required([:key, :parent_key, :summary, :status, :type])
    |> put_change(:user_id, user_scope.user.id)
  end
end
