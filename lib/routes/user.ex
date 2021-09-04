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

  post "/updateGJAccSettings20.php" do
    if Utils.is_field_missing [ "accountID" ], conn.params do
      send(conn, 400, "-1")
    else
      try do
        id = conn.params["accountID"] |> String.to_integer
        mapped_fields = %{
          "message_state" => [ key: "mS", min: 0, max: 2 ],
          "friends_state" => [ key: "frS", min: 0, max: 1 ],
          "comment_history_state" => [ key: "cS", min: 0, max: 2 ],
          "youtube" => [ key: "yt", min: nil, max: nil ],
          "twitter" => [ key: "twitter", min: nil, max: nil ],
          "twitch" => [ key: "twitch", min: nil, max: nil ]
        }

        user = User.get(id)
          |> Map.from_struct()
          |> Enum.filter(fn { user_key, _ } -> mapped_fields[Atom.to_string user_key] !== nil end)
          |> Enum.map(fn { user_key, _ } ->
            [ key: key, min: min, max: max ] = mapped_fields[Atom.to_string user_key]
            val = conn.params[key]

            if val !== nil do
              if min === nil do
                { "$set", %{ user_key => val } }
              else
                if val > min or val < max do
                  { "$set", %{ user_key => val } }
                end
              end
            end
          end)
          |> Enum.filter(&(&1 !== nil))
          |> Enum.into(%{})

        result = case Mongo.update_one(:mongo, "users", %{ _id: id }, user) do
          { :error, _ } -> false
          { :ok, _ } -> true
        end

        send(
          conn,
          (if result, do: 200, else: 500),
          (if result, do: "1", else: "-1")
        )
      rescue
        ArgumentError -> send(conn, 400, "-1")
      end

    end
  end

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
