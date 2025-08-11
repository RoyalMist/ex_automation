defmodule ExAutomation.Repo do
  use Ecto.Repo,
    otp_app: :ex_automation,
    adapter: Ecto.Adapters.Postgres
end
