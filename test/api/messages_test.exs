defmodule Api.MessagesTest do
  use ExUnit.Case, async: false
  use Plug.Test

  @options Router.init([])
  @base "/database/"
  @message_send "uploadGJMessage20.php"
  @message_list "getGJMessages20.php"
  @message_get "downloadGJMessage20.php"
  @message_del "deleteGJMessages20.php"
  @content_type "application/x-www-form-urlencoded"

  @spec list_messages(any) :: binary
  defp list_messages(state) do
    data = %{ accountID: state.first[:id], gjp: state.first[:gjp] }

    reply = conn(:post, @base <> @message_list, data)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200

    reply.resp_body
  end

  defp act_message(state, endpoint) do
    [ message_id | _ ] = list_messages(state) |> Utils.between("1:", ":") |> elem(0)
    data = %{ accountID: state.first[:id], messageID: message_id, gjp: state.first[:gjp] }

    reply = conn(:post, @base <> endpoint, data)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  setup_all do
    [ first | [ second | _ ]] =
      0..2 |> Enum.map(fn _ ->
        # Register an account
        params = Utils.test_register() |> Enum.at(0)

        # Then get its ID
        reply = Utils.test_login(params)
        id = reply.resp_body |> String.split(",") |> Enum.at(0)

        [ params: params, id: id, gjp: Utils.gjp(params.password, false) ]
      end)

    [ first: first, second: second ]
  end

  test "send message", state do
    data = %{
      accountID: state.first[:id], toAccountID: state.second[:id], gjp: state.first[:gjp],
      subject: Base.encode64("This is a test"),
      body: Base.encode64("This is a test")
    }

    reply = conn(:post, @base <> @message_send, data)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "list messages", state do
    list_messages(state)
  end

  test "get message", state do
    act_message(state, @message_get)
  end

  test "delete message", state do
    act_message(state, @message_del)
  end
end
