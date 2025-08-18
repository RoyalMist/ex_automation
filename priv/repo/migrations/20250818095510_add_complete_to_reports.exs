defmodule ExAutomation.Repo.Migrations.AddCompleteToReports do
  use Ecto.Migration

  def change do
    alter table(:reports) do
      add :complete, :boolean, default: false
    end
  end
end
