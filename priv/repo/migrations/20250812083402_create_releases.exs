defmodule ExAutomation.Repo.Migrations.CreateReleases do
  use Ecto.Migration

  def change do
    create table(:releases) do
      add :name, :string
      add :date, :naive_datetime
      add :description, :text
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:releases, [:user_id])
  end
end
