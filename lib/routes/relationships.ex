defmodule Routes.Relationships do
  alias Timex.Format.DateTime.Formatters.Relative, as: RelativeTime
  alias Models.Relationship, as: Relationship
  alias Models.Message, as: Message
  alias Models.User, as: User

  def send_friend_request(sender, receiver, params)
    when is_integer(sender) and is_integer(receiver) and is_map(params)
  do
    msg = params["comment"] || Base.encode64 "(No message provided)"

    case Base.decode64(msg) do
      :error -> false
      { :ok, decoded } -> Relationship.send_friend_request(sender, receiver, decoded)
    end
  end

  @spec read_friend_request(map) :: nonempty_binary
  def read_friend_request(params) when is_map(params) do
    r_id = params["requestID"] |> String.to_integer
    if Message.mark_as_read(r_id), do: "1", else: "-1"
  end

  @spec list_users(map) :: list
  def list_users(params) when is_map(params) do
    id = params["accountID"] |> String.to_integer
    list_blocked = if (params["type"] || "0") === "1", do: true, else: false

    Relationship.of(id, (if list_blocked, do: 2, else: 1))
      |> Enum.map(fn u ->
        User.get((u -- [id]) |> Enum.at(0))
        |> User.to_string(nil)
      end)
  end

  @spec list_friend_requests(map) :: binary
  def list_friend_requests(params) when is_map(params) do
    # ---
    id = params["accountID"] |> String.to_integer
    outgoing = if (params["getSent"] || "0") === "1", do: true, else: false

    # Get the user's relationships
    user_ids = Relationship.of(id, 0)
      |> Enum.filter(fn [ sender | _ ] -> if outgoing, do: id === sender, else: id !== sender end)

    users = user_ids |> Enum.map(fn u -> User.get((u -- [id]) |> Enum.at(0)) end)

    users
      |> Enum.map(fn u ->
        # Get friend request message
        [ msg | _ ] = if outgoing, do: Message.between(id, u._id, 1), else: Message.between(u._id, id, 1)
        content = Base.encode64(msg.content)

        # Calculate relative time
        diff = System.system_time(:millisecond) - Utils.id_to_unix(msg._id)
        age = case Timex.shift(Timex.now, milliseconds: diff) |> RelativeTime.format("{relative}") do
          { :ok, time } -> time
          _ -> "an unknown time ago"
        end

        [
          "1:#{u.username}", "2:#{u._id}", "9:#{u.icon_id}",
          "10:#{u.primary_color}", "11:#{u.secondary_color}", "14:#{u.icon_type}",
          "15:#{u.glow_id}", "16:#{u._id}", "32:#{msg._id}", "35:#{content}",
          "37:#{age}", "41:#{not msg.read}"
        ]
          |> Enum.join(":")
      end)
      |> Enum.join("|")
  end

  @spec delete_relationship(integer, integer, integer) :: boolean
  def delete_relationship(sender, receiver, status_condition)
    when is_integer(sender) and is_integer(receiver)
      and is_integer(status_condition)
  do
    op = fn r ->
      IO.inspect r
      false
    end

    case Relationship.with(sender, receiver) do
      { :error, nil } -> false
      { :ok, relationship } -> if relationship.status !== status_condition,
        do: op.(relationship), else: Relationship.delete(sender, receiver)
    end
  end

  @spec wire(Plug.Conn.t(), binary) :: { integer, binary }
  def wire(conn, route) when is_binary(route) do
    if Utils.is_field_missing [ "targetAccountID" ], conn.params do
      if Utils.is_field_missing [ "accountID" ], conn.params do
        { 400, -1 }
      else
        try do
          s = case route do
            "getGJFriendRequests20.php" -> list_friend_requests(conn.params)
            "getGJUserList20.php" -> list_users(conn.params)
            "readGJFriendRequest20.php" -> read_friend_request(conn.params)
          end

          { 200, (if s !== "", do: s, else: "-2") }
        rescue
          _ -> { 500, "-1" }
        end
      end
    else
      try do
        sender = conn.params["accountID"] |> String.to_integer
        receiver = conn.params["targetAccountID"] |> String.to_integer

        if sender !== receiver do
          success =
            case route do
              "acceptGJFriendRequest20.php" -> Relationship.accept_friend_request(sender, receiver)
              "blockGJUser20.php" -> Relationship.block(sender, receiver)
              "deleteGJFriendRequests20.php" -> delete_relationship(sender, receiver, 0)
              "removeGJFriend20.php" -> delete_relationship(sender, receiver, 1)
              "unblockGJUser20.php" -> delete_relationship(sender, receiver, 2)
              "uploadGJFriendRequest20.php" -> send_friend_request(sender, receiver, conn.params)
              _ -> nil
            end

          case success do
            true -> { 200, "1" }
            false -> { 500, "-1" }
            nil -> { 404, "Not found" }
          end
        else
          { 409, "-1" }
        end
      rescue
        ArgumentError -> { 400, "-1" }
        _ -> { 500, "-1" }
      end
    end
  end
end
