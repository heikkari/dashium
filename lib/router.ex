defmodule Router do
  use Plug.Router

  @modules [ Routes.User, Routes.Rewards, Routes.Miscellaneous, Routes.Relationships ]

  if Mix.env !== :test do
    plug Plug.Logger
  end

  plug :match
  plug Plug.Parsers, parsers: [:urlencoded]
  plug Plugs.Authentication
  plug :dispatch

  match "/database/accounts/*_", to: Routes.Authentication

  post "/database/:route" do
    replier = conn |> Plug.Conn.put_resp_content_type("text/plain")

    if String.ends_with?(route, ".php") do
      case Enum.map(@modules, &(&1.wire(conn, route))) |> Enum.filter(&(&1 !== nil)) do
        [] -> replier |> send_resp(404, "Not found!")
        [ { status, response } | _ ] -> replier |> send_resp(status, response)
      end
    else
      replier |> send_resp(404, "Not found!")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
