defmodule ExAutomation.Repo.Migrations.CreateIssues do
  use Ecto.Migration

  def change do
    create table(:issues) do
      add :key, :string
      add :parent_key, :string
      add :summary, :text
      add :status, :string
      add :type, :string
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:issues, [:user_id])
  end
end
