defmodule ExAutomation.Repo.Migrations.AddUniqueIndexToIssuesKey do
  use Ecto.Migration

  def change do
    create unique_index(:issues, [:key])
  end
end
