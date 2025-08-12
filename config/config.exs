import Config

config :ex_automation, :scopes,
  user: [
    default: true,
    module: ExAutomation.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: ExAutomation.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :ex_automation, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [data: 5, reports: 2],
  repo: ExAutomation.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 600},
    {Oban.Plugins.Cron,
     crontab: [
       {"@reboot", ExAutomation.Jobs.GitlabFetchReleasesWorker}
     ]}
  ]

config :ex_automation,
  ecto_repos: [ExAutomation.Repo],
  generators: [timestamp_type: :utc_datetime]

config :ex_automation, ExAutomationWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ExAutomationWeb.ErrorHTML, json: ExAutomationWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ExAutomation.PubSub,
  live_view: [signing_salt: "o1QbZv4e"]

config :ex_automation, ExAutomation.Mailer, adapter: Swoosh.Adapters.Local

config :esbuild,
  version: "0.25.4",
  ex_automation: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :tailwind,
  version: "4.1.7",
  ex_automation: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
