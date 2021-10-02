defmodule Routes.Comments do
  alias Models.Comment, as: Comment
  alias Models.Relationship, as: Rel

  @spec of_account(map) :: { :error | :ok, binary }
  def of_account(params) when is_map(params) do
    limit = Application.get_env(:app, :limit)
    id = params["accountID"] |> Utils.maybe_to_integer

    case Models.User.get(id) do
      -1 -> { :error, "Couldn't retrieve user" }
      user -> (
        if Rel.is_blocked(id, user._id),
          do: { :error, "The sender is blocked" },
          else: (with { :ok, comments } <- Comment.get(
            %{ author: id, type: 1 },
            skip: Utils.maybe_to_integer(params["page"]) * limit,
            limit: limit
          ) do
            comments |> as_string
          end)
      )
    end
  end

  @spec as_string([Comment]) :: { :ok, binary }
  def as_string(comments) when is_list(comments) do
    { :ok, comments
      |> Enum.map(fn comment -> Comment.to_string(comment) end)
      |> Enum.filter(fn result -> result |> elem(0) !== :error end)
      |> Enum.map(fn oks -> oks |> elem(1) end)
      |> Enum.join("|") }
  end

  @spec most_recent(map, integer) :: { :error, any } | { :ok, list }
  def most_recent(query, page) do
    limit = Application.get_env(:app, :limit)
    Comment.get(
      query, skip: page * limit, limit: limit,
      sort: %{ "_id" => -1 }
    )
  end

  @spec list(atom, map, boolean) :: { :error | any } | { :ok, binary }
  def list(type, %{ "page" => page } = params, can_view \\ false)
    when is_atom(type)
      and is_map(params)
      and is_boolean(can_view)
  do
    limit = Application.get_env(:app, :limit)
    page = page |> Utils.maybe_to_integer

    query = case type do
      :level -> %{ level_id: params["levelID"] |> Utils.maybe_to_integer }
      :history -> %{ author: params["userID"] |> Utils.maybe_to_integer }
    end |> Map.merge(%{ type: 0 }) # Level comments only

    if Map.has_key?(query, :author) and not can_view do
      case Models.User.get(query.author) do
        -1 -> { :error, "Couldn't retrieve user" }
        user -> cond do
          query.author === user._id -> list(type, params, true)
          user.comment_history_state === 2 -> { :error, "The user has a private comment history" }
          user.comment_history_state === 0 -> list(type, params, true)
          user.comment_history_state === 1 and Rel.are_friends(query.author, user._id) ->
            list(type, params, true)
        end
      end
    else
      with { :ok, comments } <- (case params["mode"] do
        "1" -> Mongo.aggregate(
          :mongo, "comments",
          [
            %{ "$match" => query },
            %{ "$project" => %{ "ratio" => %{ "$divide" => [ "$likes", "$dislikes" ] } } },
            %{ "$sort" => %{ "ratio" => -1 } }
          ],
          skip: page * limit, limit: limit
        )
        _ -> most_recent(query, page)
      end)
      do
        comments |> as_string
      end
    end
  end

  @spec list :: list
  def list() do
    [
      "getGJAccountComments20.php",
      "getGJCommentHistory.php",
      "getGJComments21.php",
      "uploadGJAccComment20.php",
      "uploadGJComment21.php"
    ]
  end

  @spec exec(Plug.Conn.t(), binary) :: { integer, binary }
  def exec(conn, route) when is_binary(route) do
    result = case route do
      "uploadGJComment21.php" -> with { :ok, decoded } <- Base.decode64(conn.params["comment"]) do
        Comment.post(
          conn.params["accountID"] |> Utils.maybe_to_integer,
          decoded,
          conn.params["levelID"] |> Utils.maybe_to_integer,
          case conn.params["percent"] do
            nil -> nil
            percent -> Utils.maybe_to_integer(percent)
          end,
          :level
        )
      end

      "uploadGJAccComment20.php" -> with { :ok, decoded } <- Base.decode64(conn.params["comment"]) do
        Comment.post(conn.params["accountID"] |> Utils.maybe_to_integer, decoded)
      end

      "getGJCommentHistory.php" -> list(:history, conn.params)
      "getGJComments21.php" -> list(:level, conn.params)
      "getGJAccountComments20.php" -> of_account(conn.params)

      r when r in ["deleteGJComment20.php", "deleteGJAccComment20.php"] ->
        Comment.delete(
          conn.params["accountID"] |> Utils.maybe_to_integer,
          conn.params["commentID"] |> Utils.maybe_to_integer
        )
    end

    case result do
      :error -> { 400, "-1" }
      { :error, _ } -> { 500, "-1" }
      { :ok, result } -> {
        200,
        (if is_binary(result),
          do: result,
          else: "-1")
      }
    end
  end
end
