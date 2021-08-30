defmodule Models.Message do
  alias Models.Relationship, as: Relationship

  defstruct [
    # Message identification
    :_id,
    :subject,

    # Sender details
    :from,
    :to,

    # Message details
    :message,
    read: false
  ]

  def list_incoming_messages(user_id) when is_integer(user_id) do
    Mongo.find(:mongo, "relations", %{ from: user_id })
      |> Enum.to_list
  end

  def send_message(sender, receiver, subject, body) do
    operation = fn s_id, r_id ->
      query = %__MODULE__{
        _id: Utils.gen_id(),
        subject: subject,
        from: s_id,
        to: r_id,
        message: body
      }

      { result, _ } = Mongo.insert_one(:mongo, "relations", Map.from_struct query)
      result === :ok
    end

    cond do
      sender === receiver -> false
      Relationship.is_blocked sender, receiver -> false
      true -> operation.(sender, receiver)
    end
  end
end
