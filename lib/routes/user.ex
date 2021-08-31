defmodule Routes.User do
  use Routes.Base

  alias Models.User, as: User
  require Logger

  post "/getGJUserInfo20.php" do
    if Utils.is_field_missing [ "targetAccountID" ], conn.params do
      send(conn, 400, "-1")
    else
      try do
        id = conn.params["accountID"]
        target = conn.params["targetAccountID"]
        user = User.get(String.to_integer target)

        send(
          conn,
          (if user === -1, do: 404, else: 200),
          (if user === -1, do: -1, else:
            user |> User.to_string(if id === nil or id === target, do: nil, else: String.to_integer id))
        )
      rescue
        # Happens if the user provides an ID that is not an integer.
        ArgumentError -> send(conn, 400, "-1")
      end
    end
  end

  post "/getGJUsers20.php" do
    if Utils.is_field_missing [ "str" ], conn.params do
      send(conn, 400, "-1")
    else
      result = User.search conn.params["str"] |> String.trim
      send(
        conn,
        (if result === "", do: 404, else: 200),
        (if result === "", do: "-1", else: result)
      )
    end
  end

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
