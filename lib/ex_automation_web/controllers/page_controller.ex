defmodule ExAutomationWeb.PageController do
  use ExAutomationWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
