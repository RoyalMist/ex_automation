defmodule ExAutomation.Gitlab.Release do
  use Ecto.Schema
  import Ecto.Changeset

  schema "releases" do
    field :name, :string
    field :date, :naive_datetime
    field :description, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(release, attrs, user_scope) do
    release
    |> cast(attrs, [:name, :date, :description])
    |> validate_required([:name, :date, :description])
    |> put_change(:user_id, user_scope.user.id)
  end
end
