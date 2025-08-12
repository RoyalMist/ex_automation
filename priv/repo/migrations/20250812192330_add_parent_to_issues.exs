defmodule ExAutomation.Repo.Migrations.AddParentToIssues do
  use Ecto.Migration

  def change do
    alter table(:issues) do
      add :parent_id, references(:issues, on_delete: :nilify_all)
    end

    create index(:issues, [:parent_id])
  end
end
