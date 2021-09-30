defmodule Router do
  use Plug.Router

  @modules [ Routes.User, Routes.Rewards, Routes.Miscellaneous, Routes.Relationships, Routes.Messages ]

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
      mods = Enum.map(@modules, fn mod -> if route in mod.list(), do: mod end)
        |> Enum.filter(fn mod -> mod !== nil end)

      case mods do
        [] -> replier |> send_resp(404, "Not found!")
        [ mod | _ ] -> (fn ->
          exec_route = fn ->
            { status, response } = mod.exec(conn, route)
            replier |> send_resp(status, response)
          end

          if Mix.env() !== :test do
            try do
              exec_route.()
            rescue
              ArgumentError -> replier |> send_resp(400, "-1")
            end
          else
            exec_route.()
          end
        end).()
      end
    else
      replier |> send_resp(404, "Not found!")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
