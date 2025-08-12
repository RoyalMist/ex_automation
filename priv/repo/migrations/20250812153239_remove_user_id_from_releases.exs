defmodule ExAutomation.Repo.Migrations.RemoveUserIdFromReleases do
  use Ecto.Migration

  def change do
    drop index(:releases, [:user_id])

    alter table(:releases) do
      remove :user_id, references(:users, type: :id, on_delete: :delete_all)
    end
  end
end
