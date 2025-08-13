defmodule ExAutomation.Reporting.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "entries" do
    field :release_name, :string
    field :release_date, :naive_datetime
    field :issue_key, :string
    field :issue_summary, :string
    field :issue_type, :string
    field :issue_status, :string
    field :initiative_key, :string
    field :initiative_summary, :string
    field :report_id, :id
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs, user_scope) do
    entry
    |> cast(attrs, [:release_name, :release_date, :issue_key, :issue_summary, :issue_type, :issue_status, :initiative_key, :initiative_summary])
    |> validate_required([:release_name, :release_date, :issue_key, :issue_summary, :issue_type, :issue_status, :initiative_key, :initiative_summary])
    |> put_change(:user_id, user_scope.user.id)
  end
end
