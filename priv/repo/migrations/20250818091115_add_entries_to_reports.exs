defmodule ExAutomation.Repo.Migrations.AddEntriesToReports do
  use Ecto.Migration

  def change do
    alter table(:reports) do
      add :entries, {:array, :map}, default: []
    end
  end
end
