defmodule ExAutomation.Reporting.Report do
  @moduledoc """
  Schema for reports with support for JSON entries.

  The `entries` field is an optional array of JSON maps that can store
  structured data about report entries. Examples of usage:

      # Simple entries
      entries: [
        %{"release_name" => "v1.0.0", "issue_key" => "PROJ-123"},
        %{"release_name" => "v1.1.0", "issue_key" => "PROJ-456"}
      ]

      # Complex nested structures
      entries: [
        %{
          "release_name" => "v2.0.0",
          "issues" => [
            %{"key" => "PROJ-100", "type" => "Epic", "status" => "Done"}
          ],
          "metadata" => %{
            "deployment_date" => "2023-12-01",
            "environment" => "production"
          }
        }
      ]
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "reports" do
    field :name, :string
    field :year, :integer
    field :user_id, :id
    field :entries, {:array, :map}, default: []
    field :complete, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(report, attrs, user_scope) do
    report
    |> cast(attrs, [:name, :year, :entries, :complete])
    |> validate_required([:name, :year])
    |> put_change(:user_id, user_scope.user.id)
  end
end
