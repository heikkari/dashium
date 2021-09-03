defmodule Router do
  use Plug.Router

  plug Plug.Logger

  plug :match
  plug Plug.Parsers, parsers: [:urlencoded]
  plug Plugs.Authentication
  plug :dispatch

  forward "/database/accounts/", to: Routes.Authentication
  forward "/database/", to: Routes.User

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
