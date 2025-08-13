defmodule ExAutomation.Repo.Migrations.UpdateEntriesReportForeignKeyCascade do
  use Ecto.Migration

  def up do
    # Drop the existing foreign key constraint
    drop constraint(:entries, "entries_report_id_fkey")

    # Add the new foreign key constraint with cascade delete
    alter table(:entries) do
      modify :report_id, references(:reports, on_delete: :delete_all)
    end
  end

  def down do
    # Drop the cascade delete foreign key constraint
    drop constraint(:entries, "entries_report_id_fkey")

    # Add back the original foreign key constraint
    alter table(:entries) do
      modify :report_id, references(:reports, on_delete: :nothing)
    end
  end
end
