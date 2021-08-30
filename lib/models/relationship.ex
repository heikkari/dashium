defmodule Models.Relationship do
  defstruct [
    :user_ids, # 0 = sender, 1 = receiver.
    :status, # 0 = friend request, 1 = friends, 2 = blocked.
    :_id
  ]

  def is_blocked(sender, receiver)
    when is_integer(sender) and is_integer(receiver)
  do
    case __MODULE__.with(sender, receiver) do
      { :error, _ } -> true
      { :ok, relationship } -> relationship.status == 2
    end
  end

  @doc """
    Sends a friend request. Inserts a Relationship struct into the database with
    a `status` value of 0.
  """
  def send_friend_request(sender, receiver)
    when is_integer(sender) and is_integer(receiver)
  do
    operation = fn s_id, r_id ->

      query = %__MODULE__{
        status: 0,
        user_ids: [ s_id, r_id ],
        _id: Utils.gen_id()
      }

      { result, _ } = Mongo.insert_one(:mongo, "relations", Map.from_struct query)
      result === :ok
    end

    cond do
      sender === receiver -> false
      is_blocked sender, receiver -> false
      true -> operation.(sender, receiver)
    end
  end

  @doc """
    Accepts a friend request.
  """
  def accept_friend_request(sender, receiver)
    when is_integer(sender) and is_integer(receiver)
  do
    query = %{ status: 0, user_ids: [ sender, receiver ] }
    { result, _ } = Mongo.update_one(:mongo, "relations", query, %{ "$set": %{ status: 1 } })
    result === :ok
  end

  def with(sender, receiver) when is_integer(sender) and is_integer(receiver) do
    case Mongo.find_one(:mongo, "relations", %{ user_ids: %{ "$in" => [ sender, receiver ] } }) do
      nil -> { :error, nil }
      document -> { :ok, document }
    end
  end

  @doc """
    Returns a list of the user's relations, filtered by the provided status.
  """
  def of(user_id, status) when is_integer(user_id) and is_integer(status) do
    # Get all documents in which the user ID is referenced
    Mongo.find(:mongo, "relations", %{ status: status, user_ids: %{ "$in" => [ user_id ] } })
      |> Enum.map(&(&1["user_ids"]))
  end

  use ExConstructor
end
