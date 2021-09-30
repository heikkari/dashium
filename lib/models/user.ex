defmodule Models.User do
  alias Models.Relationship, as: Relationship
  alias Models.Message, as: Message

  defstruct [
    # Identifiers
    :email,
    :username,
    :password,
    :_id,
    mod_level: 0,

    # Statistics
    stars: 0,
    demons: 0,
    creator_points: 0,
    secret_coins: 0,
    user_coins: 0,
    diamonds: 0,
    ranking: 0,

    # Cosmetics
    primary_color: 0,
    secondary_color: 0,
    icon_id: 0,
    ship_id: 0,
    ball_id: 0,
    bird_id: 0,
    dart_id: 0,
    robot_id: 0,
    spider_id: 0,
    trail_id: 0,
    glow_id: 0,
    explosion_id: 0,
    icon_type: 0,

    # Profile status
    message_state: 1,
    friends_state: 0,
    comment_history_state: 0,

    # Socials
    twitter: "",
    twitch: "",
    youtube: "",

    # ???
    special: 0
  ]

  @doc """
    Retrieves the number of new friends, incoming friend requests, and incoming messages.
  """
  def incoming(user_id, requester)
    when is_integer(user_id)
  do
    if user_id !== requester do
      %{
        messages: 0,
        friend_requests: 0,
        new_friends: 0
      }
    else
      %{
        # List only unread messages
        messages: Message.unread(user_id),
        # List only incoming friend requests
        friend_requests: Relationship.of(user_id, 0)
        # Filter out all the outgoing friend requests
        |> Enum.filter(&((&1 |> Enum.at(0)) === user_id))
        |> length(),
        new_friends: 0
      }
      # unimplemented
    end
  end

  def update_stats(%{
    "accountID" => id,
    "coins" => secret_coins,
    "userCoins" => user_coins
  } = params)
    when is_map(params)
  do
    user = get(id |> String.to_integer) |> Map.from_struct
    anti_cheat_settings = Application.get_env(:app, :anti_cheat)

    modified_stats =
      # TODO: Implement better anti-cheat
      Enum.map([ :stars, :demons, :diamonds ], fn stat ->
        [ max: max, max_diff: max_diff ] = anti_cheat_settings[stat]

        # Calculate new values
        new_val = params[stat |> Atom.to_string]
        diff = new_val - user[stat]

        if (new_val <= max and (new_val > user[stat]) and diff <= max_diff),
          do: { "$set", %{ stat => new_val } }
      end)
      |> Enum.filter(&(&1 !== nil))

    [ max: max_secret_coins, max_diff: diff_max_secret_coins ] = anti_cheat_settings.secret_coins
    [ max: max_user_coins, max_diff: diff_max_user_coins ] = anti_cheat_settings.user_coins

    diff_secret_coins = secret_coins - user.secret_coins
    diff_user_coins = user_coins - user.user_coins

    modified_coins = cond do
      secret_coins === user.secret_coins or user_coins === user.user_coins -> []
      secret_coins > max_secret_coins or user_coins > max_user_coins -> []
      diff_secret_coins < 0 or diff_user_coins < 0 -> []
      diff_secret_coins > diff_max_secret_coins or diff_user_coins > diff_max_user_coins -> []
      true -> [
        {"$set", %{ secret_coins: secret_coins } },
        {"$set", %{ user_coins: user_coins } }
      ]
    end

    to_dashium_case = &(((&1 |> String.downcase |> String.slice(3..-1)) <> "_id") |> String.to_atom)

    modified_icons =
      Map.keys(params)
        |> Enum.filter(&(&1 |> String.slice(0..3) === "acc"))
        |> Enum.filter(&(user[to_dashium_case.(&1)] !== (params[&1] |> String.to_integer)))
        |> Enum.map(&({ "$set", %{ to_dashium_case.(&1) => params[&1] |> String.to_integer }}))

    modified_icons = modified_icons ++ [{ "$set", %{ icon_type: params["iconType"] } }]
    Mongo.update_one(:mongo, "users", [id: id], modified_stats ++ modified_icons ++ modified_coins)
  end

  def to_string(%{ _id: user_id } = user, requester)
    when is_integer(user_id)
  do
    { _, relationship } = if requester !== nil,
      do: Relationship.with(user_id, requester),
      else: { :ok, nil }

    load_profile = fn blocked ->
      # ---
      friends_state = case relationship do
        nil -> 0
        r -> case r["status"] do
          # If the relationship is a friend request one, send 3 or 4
          0 -> if r["user_ids"] |> Enum.at(0) === user_id, do: 3, else: 4
          n -> n
        end
      end

      # ---
      %{ messages: m, friend_requests: fr, new_friends: nf } = incoming(user_id, requester)

      [
        "1:#{user.username}",
        "2:#{user._id}",
        "3:#{user.stars}",
        "4:#{user.demons}",
        "6:#{user.ranking}",
        "7:#{user._id}",
        "8:#{user.creator_points}",
        "9:#{user.icon_id}",
        "10:#{user.primary_color}",
        "11:#{user.secondary_color}",
        "13:#{user.secret_coins}",
        "14:#{user.icon_type}",
        "15:#{user.special}",
        "16:#{user._id}",
        "17:#{user.user_coins}",
        "18:#{user.message_state}",
        "19:#{user.friends_state}",
        "20:#{user.youtube}",
        "21:#{user.icon_id}",
        "22:#{user.ship_id}",
        "23:#{user.ball_id}",
        "24:#{user.bird_id}",
        "25:#{user.dart_id}",
        "26:#{user.robot_id}",
        "27:#{user.trail_id}",
        "28:#{user.glow_id}",
        "29:#{blocked}",
        "30:#{user.ranking}",
        "31:#{friends_state}",
        "38:#{m}",
        "39:#{fr}",
        "40:#{nf}",
        "41:0",
        "43:#{user.spider_id}",
        "44:#{user.twitter}",
        "45:#{user.twitch}",
        "46:#{user.diamonds}",
        "48:#{user.explosion_id}",
        "49:#{user.mod_level}",
        "50:#{user.comment_history_state}"
      ]
        |> Enum.join(":")
    end

    if relationship["status"] === 2 do
      # Refuse request if blocked
      [ _ | [ blockee | _ ] ] = relationship["user_ids"]
      if blockee == user_id, do: "-1", else: load_profile.(1)
    else
      load_profile.(0)
    end
  end

  def get(user_id) when is_integer(user_id) do
    case Mongo.find_one(:mongo, "users", %{ _id: user_id }) do
      nil -> -1
      document -> new(document)
    end
  end

  def search(str) when is_binary(str) do
    query = %{ "$text" => %{ "$search" => str } }
    options = [ score: %{ "$meta" => "textScore" } ]

    Mongo.find(:mongo, "users", query, options)
      |> Enum.filter(fn user -> user["score"] > 0.6 end)
      |> Enum.map(fn user -> new(user) |> to_string(nil) end)
      |> Enum.join("|")
  end

  use ExConstructor
end
