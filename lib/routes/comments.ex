defmodule Routes.Comments do
  alias Models.Comment, as: Comment

  @spec as_string([Comment]) :: { :ok, binary }
  def as_string(comments) when is_list(comments) do
    { :ok, comments
      |> Enum.map(fn comment -> comment |> Comment.to_string end)
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

  @spec list(atom, map) :: { :error | any } | { :ok, binary }
  def list(type, %{ "page" => page } = params) when is_atom(type) do
    limit = Application.get_env(:app, :limit)
    page = page |> String.to_integer
    query = case type do
      :level -> %{ level_id: params["levelID"] |> String.to_integer }
      :history -> %{ author: params["userID"] |> String.to_integer }
    end |> Map.merge(%{ type: 0 }) # Level comments only

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
    if Utils.is_field_missing ["accountID"], conn.params do
      limit = Application.get_env(:app, :limit)
      id = conn.params["accountID"] |> String.to_integer

      case route do
        "uploadGJComment21.php" -> with { :ok, decoded } <- Base.decode64(conn.params["comment"]) do
          Comment.post(
            id, decoded,
            conn.params["levelID"] |> String.to_integer,
            conn.params["percent"] |> String.to_integer,
            :level
          )
        end

        "uploadGJAccComment20.php" -> with { :ok, decoded } <- Base.decode64(conn.params["comment"]) do
          Comment.post(id, decoded)
        end

        "getGJCommentHistory.php" -> list(:history, conn.params)
        "getGJComments21.php" -> list(:level, conn.params)

        "getGJAccountComments20.php" -> with { :ok, comments } <- Comment.get(
          %{ author: id, type: 1 },
          skip: String.to_integer(conn.params["page"]) * limit,
          limit: limit
        ) do
          comments |> as_string
        end

        r when r in ["deleteGJComment20.php", "deleteGJAccComment20.php"] ->
          Comment.delete(id, conn.params["commentID"] |> String.to_integer)
      end
    else

    end

  end
end
