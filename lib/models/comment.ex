defmodule Models.Comment do
  defstruct [
    :_id,
    :author,
    :likes,
    :dislikes,
    :body,
    :type, # 0 - level, 1 - profile
    :level,
    :percent,
  ]

  @spec to_string(Models.Comment) :: {:ok | :error, binary}
  def to_string(%__MODULE__{ type: type } = comment) do
    user = Models.User.get(comment.author)

    values = case type do
      0 -> case user do
        -1 -> { :error, "Couldn't get user" }
        user -> { :ok,
          [
            %{
              1 => comment.level,
              2 => comment.body |> Base.encode64,
              3 => comment.author,
              4 => comment.likes - comment.dislikes,
              5 => comment.dislikes,
              6 => comment._id,
              7 => (
                if comment.likes / comment.dislikes < Application.get_env(:app, :spam_ratio),
                do: 0,
                else: 1
              ),
              8 => comment.author,
              9 => Utils.age(comment),
              10 => comment.percent,
              11 => user.mod_level,
              12 => Application.get_env(:app, :spam_ratio)[user.mod_level]
                |> Enum.map(fn value -> Integer.to_string(value, 16) end)
                |> Enum.join(",")
            },

            %{
              1 => user.username,
              9 => user.icon_id,
              10 => user.primary_color,
              11 => user.secondary_color,
              14 => user.icon_type,
              15 => user.glow_id,
              16 => user._id
            }
          ]
        }
      end

      1 -> {
        :ok,
        [ %{
          2 => comment.body |> Base.encode64,
          4 => comment.likes - comment.dislikes,
          9 => Utils.age(comment),
          6 => comment._id
        } ]
      }

      _ -> throw "Invalid comment type"
    end

    with { :ok, list } <- values do
      { :ok, list
        |> Enum.map(fn elem ->
          Enum.map(elem, fn { key, value } -> Enum.join([ key, value ], "~") end)
            |> Enum.join("~")
        end)
        |> Enum.join(":") }
    end
  end

  @spec get(map, keyword) :: { :error, any } | { :ok, list }
  def get(query, opts \\ []) when is_map(query) do
    case Mongo.find(:mongo, "comments", query, opts) do
      { :error, e } -> { :error, e }
      cursor -> { :ok, cursor |> Enum.map(fn doc -> new(doc) end) }
    end
  end

  @spec by_id(integer) :: { :error, any } | { :ok, __MODULE__ }
  def by_id(id) when is_integer(id) do
    with { :ok, [ comment | _ ] } <- get(%{ _id: id }) do
      { :ok, comment }
    end
  end

  @spec delete(integer, integer) :: { :ok | :error, binary | Mongo.DeleteResult.t | any }
  def delete(user_id, comment_id)
    when is_integer(user_id) and is_integer(comment_id)
  do
    with { :ok, comment } <- by_id(comment_id) do
      can_delete = if comment.author !== user_id do
        mod_level = Application.get_env(:app, :delete_comments)
        user = Models.User.get(user_id)
        user.mod_level >= mod_level
      else
        true
      end

      if can_delete do
        Mongo.delete_one(:mongo, "comments", %{ _id: comment_id })
      else
        { :error, "not allowed" }
      end
    end
  end

  @spec post(integer, binary, integer | nil, atom) :: { :ok | :error, Mongo.InsertOneResult.t() }
  def post(user_id, body, level_id \\ nil, percent \\ nil, type \\ :profile)
    when is_integer(user_id)
      and is_nil(level_id) or is_integer(level_id)
      and is_binary(body)
      and is_atom(type)
  do
    # TODO: Check if `level_id` exists

    Mongo.insert_one(:mongo, "comments", %{
      _id: Utils.gen_id(),
      author: user_id,
      likes: 0,
      dislikes: 0,
      body: body,
      type: case type do
        :level -> 0
        :profile -> 1
        opt -> throw "Invalid option #{opt}"
      end,
      level_id: level_id,
      percent: percent
    })
  end

  use ExConstructor
end
