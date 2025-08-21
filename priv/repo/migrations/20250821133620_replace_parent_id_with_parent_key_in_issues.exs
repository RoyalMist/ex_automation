defmodule ExAutomation.Repo.Migrations.ReplaceParentIdWithParentKeyInIssues do
  use Ecto.Migration

  def change do
    alter table(:issues) do
      remove :parent_id, references(:issues, on_delete: :nilify_all)
      add :parent_key, :string
    end

    create index(:issues, [:parent_key])
  end
end
