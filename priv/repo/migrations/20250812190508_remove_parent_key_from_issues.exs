defmodule ExAutomation.Repo.Migrations.RemoveParentKeyFromIssues do
  use Ecto.Migration

  def change do
    alter table(:issues) do
      remove :parent_key, :string
    end
  end
end
