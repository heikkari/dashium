defmodule Models.Relationship do
  defstruct [
    :user_ids, # 0 = sender, 1 = receiver.
    :status, # 0 = friend request, 1 = friends, 2 = blocked.
  ]

  @spec delete(integer, integer) :: boolean
  def delete(sender, receiver)
    when is_integer(sender) and is_integer(receiver)
  do
    query = %{ user_ids: %{ "$in" => [ sender, receiver ] } }
    { status, _ } = Mongo.delete_one(:mongo, "relationships", query)
    status === :ok
  end

  @spec exists(integer, integer) :: boolean
  def exists(sender, receiver)
    when is_integer(sender) and is_integer(receiver)
  do
    { status, _ } = __MODULE__.with(sender, receiver)
    status === :ok
  end

  @spec update(integer, integer, integer) :: boolean
  def update(sender, receiver, status)
    when is_integer(sender) and is_integer(receiver) and is_integer(status)
  do
    query = %{ status: 0, user_ids: %{ "$in" => [ sender, receiver ] } }
    { result, _ } = Mongo.update_one(:mongo, "relationships", query, %{ "$set": %{ status: status } })
    result === :ok
  end

  @spec create(integer, integer, integer) :: boolean
  def create(sender, receiver, status)
    when is_integer(sender) and is_integer(receiver) and is_integer(status)
  do
    if not exists(sender, receiver) do
      query = %__MODULE__{
        status: status,
        user_ids: [ sender, receiver ],
      }

      { result, _ } = Mongo.insert_one(:mongo, "relationships", Map.from_struct query)
      result === :ok
    else
      true
    end
  end

  @spec is_blocked(integer, integer) :: boolean
  def is_blocked(sender, receiver)
    when is_integer(sender) and is_integer(receiver)
  do
    case __MODULE__.with(sender, receiver) do
      { :error, _ } -> false
      { :ok, relationship } -> relationship.status == 2
    end
  end

  @spec are_friends(integer, integer) :: boolean
  def are_friends(sender, receiver)
    when is_integer(sender) and is_integer(receiver)
  do
    case __MODULE__.with(sender, receiver) do
      { :error, _ } -> false
      { :ok, relationship } -> relationship.status == 1
    end
  end

  @doc """
    Sends a friend request. Inserts a Relationship struct into the database with
    a `status` value of 0. Returns an HTTP status code.
  """
  @spec send_friend_request(integer, integer, binary) :: boolean
  def send_friend_request(sender, receiver, msg)
    when is_integer(sender) and is_integer(receiver) and is_binary(msg)
  do
    operation = fn ->
      x = create(sender, receiver, 0)
      y = Models.Message.send(sender, receiver, 1, "Friend request", msg)
      x and y
    end

    cond do
      sender === receiver -> false
      is_blocked sender, receiver -> false
      are_friends sender, receiver -> false
      true -> operation.()
    end
  end

  @doc """
    Accepts a friend request.
  """
  @spec accept_friend_request(integer, integer) :: boolean
  def accept_friend_request(sender, receiver)
    when is_integer(sender) and is_integer(receiver)
  do
    case __MODULE__.with(sender, receiver) do
      { :error, nil } -> false
      { :ok, document } -> if document.status === 0,
        do: update(sender, receiver, 1),
        else: false
    end
  end

  @spec block(integer, integer) :: boolean
  def block(sender, receiver) do
    x = create(sender, receiver, 0) # Create a relationship between the users if there isn't one
    y = update(sender, receiver, 2) # Update the status to 2 (Blocked)
    x and y
  end

  @spec with(integer, integer) :: any
  def with(sender, receiver) when is_integer(sender) and is_integer(receiver) do
    case Mongo.find_one(:mongo, "relationships", %{ user_ids: %{ "$in" => [ sender, receiver ] } }) do
      nil -> { :error, nil }
      document -> { :ok, new(document) }
    end
  end

  @doc """
    Returns a list of the user's relations, filtered by the provided status.
  """
  @spec of(integer, integer) :: list
  def of(user_id, status) when is_integer(user_id) and is_integer(status) do
    # Get all documents in which the user ID is referenced
    Mongo.find(:mongo, "relationships", %{ status: status, user_ids: %{ "$in" => [ user_id ] } })
      |> Enum.map(&(&1["user_ids"]))
  end

  use ExConstructor
end
