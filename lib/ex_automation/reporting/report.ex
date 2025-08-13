defmodule ExAutomation.Reporting.Report do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reports" do
    field :name, :string
    field :year, :integer
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(report, attrs, user_scope) do
    report
    |> cast(attrs, [:name, :year])
    |> validate_required([:name, :year])
    |> put_change(:user_id, user_scope.user.id)
  end
end
