import Config

config :ex_automation, ExAutomation.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ex_automation_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :ex_automation, ExAutomationWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "I0zHPPlWmKoYr5BV+Y87rCVa3LnMi7bEFekgEJpffR3jYcJEcm+gNVnarAGNDRK3",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:ex_automation, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:ex_automation, ~w(--watch)]}
  ]

config :ex_automation, ExAutomationWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/ex_automation_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
    ]
  ]

config :ex_automation, dev_routes: true

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true,
  enable_expensive_runtime_checks: true

config :swoosh, :api_client, false
