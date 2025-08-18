defmodule ExAutomation.Repo.Migrations.DropEntriesTable do
  use Ecto.Migration

  def change do
    drop table(:entries)
  end
end
