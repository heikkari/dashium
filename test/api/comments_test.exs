defmodule Api.CommentsTest do
  use ExUnit.Case, async: false
  use Plug.Test

  @options Router.init([])
  @base "/database/"
  @comment_level_post "uploadGJComment21.php"
  @comment_profi_post "uploadGJAccComment20.php"
  @comment_history "getGJCommentHistory.php"
  @message_del "deleteGJMessages20.php"
  @content_type "application/x-www-form-urlencoded"

  @spec send_request(map, binary, map) :: binary
  defp send_request(state, endpoint, map \\ %{}) do
    data = %{ accountID: state.id, gjp: state.gjp } |> Map.merge(map)

    reply = conn(:post, @base <> endpoint, data)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200

    reply.resp_body
  end

  setup_all do
    # Register an account
    params = Utils.test_register() |> Enum.at(0)

    # Then get its ID
    reply = Utils.test_login(params)
    id = reply.resp_body |> String.split(",") |> Enum.at(0)

    [ params: params, id: id, gjp: Utils.gjp(params.password, false) ]
  end

  test "post level comment", state do
    send_request(
      state, @comment_level_post,
      %{
        levelID: "1337",
        comment: Base.encode64("This is a test")
      }
    )
  end

  test "post profile comment", state do
    send_request(
      state, @comment_profi_post,
      %{
        comment: Base.encode64("This is a test")
      }
    )
  end

  test "comment history", state do
    send_request(
      state, @comment_history,
      %{
        page: 0,
        userID: state.id
      }
    )
  end
end
