defmodule Routes.Messages do
  alias Models.Message, as: Message

  @spec list(map, integer, boolean) :: binary
  defp list(params, sender, get_sent)
    when is_map(params)
      and is_integer(sender)
      and is_boolean(get_sent)
  do
    Message.of(sender, (params["page"] || "0") |> String.to_integer, get_sent)
      |> Enum.map(fn message -> message |> Message.to_string(sender) end)
      |> Enum.join("|")
  end

  @spec upload(map, integer) :: boolean
  defp upload(params, sender) when is_map(params) and is_integer(sender) do
    receiver = params["toAccountID"] |> String.to_integer
    [ subject | [ body | _ ]] = [ "subject", "body" ]
      |> Enum.map(fn field -> params[field] |> Base.decode64 |> elem(1) end)
    Message.send(sender, receiver, 0, subject, body)
  end

  @spec wire(Plug.Conn.t(), binary) :: { integer, binary }
  def wire(conn, route) when is_binary(route) do
    if Utils.is_field_missing ["accountID"], conn.params do
      { 401, "-1" }
    else
      try do
        sender = conn.params["accountID"] |> String.to_integer

        response = if Utils.is_field_missing ["messageID"], conn.params do
          case route do
            "getGJMessages20.php" -> __MODULE__.list((if (conn.params["getSent"] || "0") === "1", do: true, else: false))
            "uploadGJMessage20.php" -> upload(conn.params, sender)
            _ -> nil
          end
        else
          id = conn.params["messageID"] |> String.to_integer

          case route do
            "deleteGJMessages20.php" -> Message.delete(id, sender)
            "downloadGJMessage20.php" -> Message.get(id) |> Message.to_string(sender)
            _ -> nil
          end
        end

        cond do
          is_binary(response) -> { 200, response }
          is_boolean(response) -> {
            (if response, do: 200, else: 500),
            (if response, do: "1", else: "-1")
          }
          true -> nil
        end
      rescue
        ArgumentError -> { 400, "-1" }
        _ -> { 500, "-1" }
      end
    end
  end
end
