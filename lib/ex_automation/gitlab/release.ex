defmodule ExAutomation.Gitlab.Release do
  use Ecto.Schema
  import Ecto.Changeset

  schema "releases" do
    field :name, :string
    field :date, :naive_datetime
    field :description, :string
    field :tags, {:array, :string}, default: []
    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new release.

  Only allows casting of core fields (name, date, description).
  Tags are not allowed during creation and will be ignored.
  """
  def changeset(release, attrs) do
    release
    |> cast(attrs, [:name, :date, :description])
    |> validate_required([:name, :date, :description])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset for updating an existing release.

  Allows casting of all fields including tags.
  Use this changeset when updating releases to modify tags.
  """
  def update_changeset(release, attrs) do
    release
    |> cast(attrs, [:name, :date, :description, :tags])
    |> validate_required([:name, :date, :description])
    |> unique_constraint(:name)
  end
end
