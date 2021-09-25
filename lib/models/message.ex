defmodule Models.Message do
  alias Timex.Format.DateTime.Formatters.Relative, as: RelativeTime
  alias Models.Relationship, as: Relationship
  alias Models.User, as: User

  defstruct [
    # Message identification
    :_id,
    :subject,
    :type, # 0 - normal, 1 - friend request

    # Sender details
    :from,
    :to,
    :hide, # hide from sender if true

    # Message details
    :content,
    read: false
  ]

  @spec unread(integer) :: integer
  def unread(sender) when is_integer(sender) do
    Message.find(:mongo, "messages", %{ to: sender, hide: false, read: false })
      |> Enum.to_list
      |> length
  end

  @spec delete(integer, integer) :: boolean
  def delete(id, sender) when is_integer(id) and is_integer(sender) do
    { status, _ } = if get(id).from === sender do
      Mongo.delete_one(:mongo, "messages", %{ _id: id })
    else
      Mongo.update_one(:mongo, "messages", %{ _id: id }, %{ "$set" => %{ hide: true } })
    end

    status === :ok
  end

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

  @spec to_string(Models.Message, integer) :: binary
  def to_string(message, sender) when is_integer(sender) do
    list = [
      message._id,
      message.from,
      message.from,
      message.subject |> Base.encode64,
      message.content |> Utils.xor(:messages) |> Base.encode64,
      User.get(message.from).username,
      age(message),
      (if message.read, do: "1", else: "0"),
      (if message.from === sender, do: "1", else: "0")
    ]

    1..length(list) |> Stream.zip(list) |> Enum.into(%{})
  end

  @spec age(Models.Message) :: binary
  def age(msg) do
    diff = System.system_time(:millisecond) - Utils.id_to_unix(msg._id)
    case Timex.shift(Timex.now, milliseconds: diff) |> RelativeTime.format("{relative}") do
      { :ok, time } -> time
      _ -> "an unknown time ago"
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

  @spec of(integer, integer, boolean, integer) :: list
  def of(user_id, page \\ 0, incoming \\ true, type \\ 0)
    when is_integer(user_id)
      and is_integer(page)
      and is_boolean(incoming)
      and is_integer(type)
  do
    limit = Application.get_env(:app, :limit)

    query = if incoming do
      %{ to: user_id, type: type, hide: false }
    else
      %{ from: user_id, type: type }
    end

    Mongo.find(
      :mongo, "messages", query,
      sort: %{ _id: -1 },
      skip: page * limit,
      limit: limit
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
        hide: false,
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
