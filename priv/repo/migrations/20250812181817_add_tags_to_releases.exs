defmodule ExAutomation.Repo.Migrations.AddTagsToReleases do
  use Ecto.Migration

  def change do
    alter table(:releases) do
      add :tags, {:array, :string}, default: []
    end
  end
end
