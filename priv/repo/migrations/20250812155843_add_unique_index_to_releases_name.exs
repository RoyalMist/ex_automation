defmodule ExAutomation.Repo.Migrations.AddUniqueIndexToReleasesName do
  use Ecto.Migration

  def change do
    create unique_index(:releases, [:name])
  end
end
