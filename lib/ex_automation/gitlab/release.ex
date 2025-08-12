defmodule ExAutomation.Gitlab.Release do
  use Ecto.Schema
  import Ecto.Changeset

  schema "releases" do
    field :name, :string
    field :date, :naive_datetime
    field :description, :string
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(release, attrs) do
    release
    |> cast(attrs, [:name, :date, :description])
    |> validate_required([:name, :date, :description])
  end
end
