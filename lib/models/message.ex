defmodule Models.Message do
  alias Models.Relationship, as: Relationship

  defstruct [
    # Message identification
    :_id,
    :subject,
    :type, # 0 - normal, 1 - friend request

    # Sender details
    :from,
    :to,

    # Message details
    :content,
    read: false
  ]

  @spec mark_as_read(integer) :: boolean
  def mark_as_read(id) when is_integer(id) do
    { status, _ } = Mongo.update_one(:mongo, "messages", %{ _id: id }, %{ "$set" => %{ read: true } })
    status === :ok
  end

  @spec get(integer) :: { :error, :message_not_found } | { :ok, Models.Message }
  def get(id) when is_integer(id) do
    case Mongo.find_one(:mongo, "messages", %{ _id: id }) do
      nil -> { :error, :message_not_found }
      document -> { :ok, new(document) }
    end
  end

  @spec between(integer, integer, integer, integer) :: list
  def between(sender, receiver, type \\ 0, limit \\ 10)
    when is_integer(sender) and is_integer(receiver)
    and is_integer(type) and is_integer(limit)
  do
    query = %{ from: sender, to: receiver, type: type }
    Mongo.find(:mongo, "messages", query, sort: %{ _id: -1 }, limit: limit) |> Enum.map(&(new(&1)))
  end

  @spec incoming(integer, integer, integer) :: list
  def incoming(user_id, type \\ 0, limit \\ 10)
    when
      is_integer(user_id) and is_integer(type)
      and is_integer(limit)
  do
    Mongo.find(
      :mongo, "messages",
      %{ from: user_id, type: type },
      sort: %{ _id: -1 }, limit: limit
    )
    |> Enum.to_list
    |> Enum.map(&(new(&1)))
  end

  @spec send(integer, integer, integer, binary, binary) :: boolean
  def send(sender, receiver, type, subject, body)
    when
      is_integer(sender) and is_integer(receiver) and
      is_binary(subject) and is_binary(body) and
      is_integer(type)
  do
    operation = fn s_id, r_id ->
      query = %__MODULE__{
        _id: Utils.gen_id(),
        subject: subject,
        type: type,
        from: s_id,
        to: r_id,
        content: body
      }

      { result, _ } = Mongo.insert_one(:mongo, "messages", Map.from_struct query)
      result === :ok
    end

    cond do
      sender === receiver -> false
      Relationship.is_blocked sender, receiver -> false
      true -> operation.(sender, receiver)
    end
  end

  use ExConstructor
end
