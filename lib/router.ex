defmodule Router do
  use Plug.Router

  if Mix.env !== :test do
    plug Plug.Logger
  end

  plug :match
  plug Plug.Parsers, parsers: [:urlencoded]
  plug Plugs.Authentication
  plug :dispatch

  match "/database/accounts/*_", to: Routes.Authentication
  match "/database/*_", to: Routes.User

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
