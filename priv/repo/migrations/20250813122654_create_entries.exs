defmodule ExAutomation.Repo.Migrations.CreateEntries do
  use Ecto.Migration

  def change do
    create table(:entries) do
      add :release_name, :string
      add :release_date, :naive_datetime
      add :issue_key, :string
      add :issue_summary, :string
      add :issue_type, :string
      add :issue_status, :string
      add :initiative_key, :string
      add :initiative_summary, :string
      add :report_id, references(:reports, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:entries, [:user_id])

    create index(:entries, [:report_id])
  end
end
