import Config

config :bcrypt_elixir, :log_rounds, 1
config :ex_automation, Oban, testing: :manual

config :ex_automation, ExAutomation.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ex_automation_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :ex_automation, ExAutomationWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Me8Wkj6+fNk5C7w5QWcueKzS6Nw0+iz8RTwQLJ0OH4uEU4WO3EZsl9AtlWLJQDnd",
  server: false

config :ex_automation, ExAutomation.Mailer, adapter: Swoosh.Adapters.Test

config :swoosh, :api_client, false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  enable_expensive_runtime_checks: true
