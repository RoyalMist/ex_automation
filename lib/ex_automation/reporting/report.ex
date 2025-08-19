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

  ## Complete Field

  The `complete` field indicates whether a report has finished processing:
  - Defaults to `false` when a report is created
  - Cannot be set to `true` during creation (use `create_changeset/3`)
  - Can be updated to `true` after creation (use `changeset/3`)
  - Automatically set to `true` by MonthlyReportWorker when job completes
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

  @doc """
  Changeset for creating a new report.

  The complete field is not allowed during creation as it should only be set
  programmatically when a report processing job finishes.
  """
  def create_changeset(report, attrs, user_scope) do
    report
    |> cast(attrs, [:name, :year, :entries])
    |> validate_required([:name, :year])
    |> put_change(:user_id, user_scope.user.id)
  end

  @doc """
  Changeset for updating an existing report.

  Allows updating all fields including the complete field.
  """
  def changeset(report, attrs, user_scope) do
    report
    |> cast(attrs, [:name, :year, :entries, :complete])
    |> validate_required([:name, :year])
    |> put_change(:user_id, user_scope.user.id)
  end
end
