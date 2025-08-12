defmodule ExAutomationWeb.Router do
  use ExAutomationWeb, :router

  import ExAutomationWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ExAutomationWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ExAutomationWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  if Application.compile_env(:ex_automation, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: ExAutomationWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", ExAutomationWeb do
    import Oban.Web.Router
    pipe_through [:browser, :require_authenticated_user]
    oban_dashboard("/workflows")

    live_session :require_authenticated_user,
      on_mount: [{ExAutomationWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/releases", ReleaseLive.Index, :index
      live "/releases/:id", ReleaseLive.Show, :show
      live "/issues", IssueLive.Index, :index
      live "/issues/:id", IssueLive.Show, :show
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", ExAutomationWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{ExAutomationWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
