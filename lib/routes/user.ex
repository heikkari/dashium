defmodule Routes.User do
  alias Models.User, as: User

  defp get_user_info(conn) do
    if Utils.is_field_missing [ "targetAccountID" ], conn.params do
      { 400, "-1" }
    else
      try do
        id = conn.params["accountID"]
        target = conn.params["targetAccountID"]
        user = User.get(String.to_integer target)

        {
          (if user === -1, do: 404, else: 200),
          (if user === -1, do: "-1", else:
            user |> User.to_string(if id === nil or id === target, do: nil, else: String.to_integer id))
        }
      rescue
        # Happens if the user provides an ID that is not an integer.
        ArgumentError -> { 400, "-1" }
      end
    end
  end

  defp search_users(conn) do
    if Utils.is_field_missing [ "str" ], conn.params do
      { 400, "-1" }
    else
      result = User.search conn.params["str"] |> String.trim
      {
        (if result === "", do: 404, else: 200),
        (if result === "", do: "-1", else: result)
      }
    end
  end

  defp update_settings(conn) do
    if Utils.is_field_missing [ "accountID" ], conn.params do
      { 401, "-1" }
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

        {
          (if result, do: 200, else: 500),
          (if result, do: "1", else: "-1")
        }
      rescue
        ArgumentError -> { 400, "-1" }
      end

    end
  end

  defp update_score(conn) do
    fields = [
      "accountID", "userCoins", "demons", "stars",
      "coins", "iconType", "icon", "diamonds",
      "accIcon", "accShip", "accBall", "accBird",
      "accDart", "accRobot", "accGlow", "accSpider",
      "accExplosion"
    ]

    if Utils.is_field_missing fields ++ ["seed2"], conn.params do
      { 400, "-1" }
    else
      try do
        values = fields |> Enum.map(&(conn.params[&1]))
        chk = Utils.chk(values, :user_profile)

        if chk === conn.params["seed2"] do
          case User.update_stats(conn.params) do
            { :error, _ } -> { 500, "-1" }
            { :ok, _ } -> { 200, "1" }
          end
        else
          { 401, "-1" }
        end
      rescue
        ArgumentError -> { 400, "-1" }
      end
    end
  end

  @spec wire(Plug.Conn.t(), binary) :: nil | { integer, binary }
  def wire(conn, route) when is_binary(route) do
    case route do
      "updateGJUserScore22.php" -> update_score(conn)
      "updateGJAccSettings20.php" -> update_settings(conn)
      "getGJUserInfo20.php" -> get_user_info(conn)
      "getGJUsers20.php" -> search_users(conn)
      _ -> nil
    end
  end
end
