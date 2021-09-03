defmodule Plugs.Authentication do
  import Plug.Conn
  alias Models.Account, as: Account

  def init(options) do
    options
  end

  defp send_401(conn) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(401, "-1")
    |> halt
  end

  defp authenticate(conn) do
    user_id = conn.params["accountID"]
    gjp = conn.params["gjp"]

    if user_id !== nil do
      if gjp === nil do
        send_401(conn)
      else
        if not Account.auth(user_id |> String.to_integer, gjp),
          do: send_401(conn)
      end
    end
  end

  def call(conn, _) do
    conn |> authenticate
  end
end
