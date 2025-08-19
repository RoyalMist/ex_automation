defmodule ExAutomation.Repo.Migrations.RenameCompleteToCompletedInReports do
  use Ecto.Migration

  def change do
    rename table(:reports), :complete, to: :completed
  end
end
