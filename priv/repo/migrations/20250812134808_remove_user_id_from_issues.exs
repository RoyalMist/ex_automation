defmodule ExAutomation.Repo.Migrations.RemoveUserIdFromIssues do
  use Ecto.Migration

  def change do
    drop index(:issues, [:user_id])

    alter table(:issues) do
      remove :user_id, references(:users, type: :id, on_delete: :delete_all)
    end
  end
end
