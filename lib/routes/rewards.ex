defmodule Routes.Rewards do
  defp salt(data, key) when is_atom(key) do
    :crypto.hash(:sha, data <> Application.get_env(:app, :salt)[key])
      |> Base.encode16
      |> String.downcase
  end

  defp generate_quests() do
    Enum.map [ orbs: 1, coins: 2, stars: 3 ], fn {k, v} ->
      [ names: names, min: min, max: max, diamond_multiplier: d ] = Application.get_env(:app, :quests)[k]
      amount = Enum.random(min..max)

      ([ v, amount, amount * d |> Kernel.trunc ]
        |> Enum.map(&(Integer.to_string &1)))
        ++ [Enum.random(names)]
        |> Enum.join(",")
    end
  end

  defp generate_reward(
    udid,
    reward_type,
    user_id
  )
    when is_binary(udid)
      and is_binary(user_id)
      and is_binary(reward_type)
  do
    type = if reward_type === "1", do: :large, else: :small

    create_entry = fn ->
      query = %{ _id: udid, large: 0, small: 0 }
      Mongo.insert_one(:mongo, "rewards", query)
      { 0, 0 }
    end

    { large, small } = case Mongo.find_one(:mongo, "rewards", %{ _id: udid }) do
      nil -> create_entry.()
      document -> { document["large"], document["small"] }
    end

    generate_chest = fn ->
      rewards = Application.get_env(:app, :rewards)
      [
        orbs: [ min: min_orbs, max: max_orbs ],
        diamonds: [ min: min_diamonds, max: max_diamonds ],
        timeout_hours: timeout
      ] = rewards[type]

      until = DateTime.add(DateTime.utc_now(), timeout * 3600) |> DateTime.to_unix
      Mongo.update_one(:mongo, "rewards", %{ _id: udid }, %{ "$set" => %{ type => until } })

      [
        Enum.random(min_orbs..max_orbs),
        Enum.random(min_diamonds..max_diamonds),
        Enum.random(1..4),
        Enum.random(0..1)
      ]
        |> Enum.join(",")
    end

    # ---
    now = DateTime.utc_now()
    large_remaining = if large === 0, do: 0, else: DateTime.diff(DateTime.from_unix!(large), now)
    small_remaining = if small === 0, do: 0, else: DateTime.diff(DateTime.from_unix!(small), now)

    # ---
    large_remaining = if large_remaining < 0, do: 0, else: large_remaining
    small_remaining = if small_remaining < 0, do: 0, else: small_remaining

    str =
      [
        Utils.random_string(5),
        "0", "0",
        udid, user_id,
        large_remaining |> Integer.to_string,
        (if type === :small, do: generate_chest.(), else: "-"),
        small_remaining |> Integer.to_string,
        (if type === :large, do: generate_chest.(), else: "-"),
        "0",
        reward_type
      ]
        |> Enum.join(":")
        |> Utils.xor(:rewards)
        |> Base.encode64

    "#{Utils.random_string(5)}#{str}|#{salt(str, :rewards)}"
  end

  defp get_challenges(conn) do
    get = &(if conn.params[&1] === nil, do: "0", else: conn.params[&1])

    attributes = [
      Utils.random_string(5),
      get.("accountID"), "0",
      get.("udid"),
      get.("accountID"),
      Time.diff(~T[23:59:59.999], Time.utc_now) |> Integer.to_string
    ]

    str = Utils.xor(attributes ++ generate_quests() |> Enum.join(":"), :quests) |> Base.encode64()
    { 200, "#{Utils.random_string(5)}#{str}|#{salt(str, :quests)}" }
  end

  defp get_rewards(conn) do
    if Utils.is_field_missing [ "udid", "rewardType" ], conn.params do
      { 400, "-1" }
    else
      udid = conn.params["udid"]

      if String.length(udid) !== 36 or length(udid |> String.split("-")) !== 5 do
        { 400, "-1" }
      else
        user_id = if conn.params["accountID"] === nil, do: "0", else: conn.params["accountID"]
        { 200, generate_reward(udid, conn.params["rewardType"], user_id) }
      end
    end
  end

  @spec list :: list
  def list() do
    [ "getGJRewards.php", "getGJChallenges.php" ]
  end

  @spec exec(Plug.Conn.t(), binary) :: { integer, binary }
  def exec(conn, route) when is_binary(route) do
    case route do
      "getGJRewards.php" -> get_rewards(conn)
      "getGJChallenges.php" -> get_challenges(conn)
    end
  end
end
