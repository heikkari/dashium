defmodule Api.RelationshipsTest do
  use ExUnit.Case, async: false
  use Plug.Test

  @options Router.init([])
  @base "/database/"
  @friend_add "uploadGJFriendRequest20.php"
  @friend_accept "acceptGJFriendRequest20.php"
  @friend_remove "removeGJFriend20.php"
  @friends_list "getGJUserList20.php"
  @user_block "blockGJUser20.php"
  @user_unblock "unblockGJUser20.php"
  @freq_remove "deleteGJFriendRequests20.php"
  @freq_list "getGJFriendRequests20.php"
  @content_type "application/x-www-form-urlencoded"

  @spec confirm_relationship_endpoint(any, binary) :: none
  def confirm_relationship_endpoint(state, endpoint) when is_binary(endpoint) do
    data = %{ accountID: state.first[:id], targetAccountID: state.second[:id], gjp: state.first[:gjp] }

    reply = conn(:post, @base <> endpoint, data)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  def send_friend_request(state) do
    confirm_relationship_endpoint(state, @friend_add)
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

  test "send friend request", state do
    send_friend_request(state)
  end

  test "list incoming friend requests", state do
    data = %{ accountID: state.first[:id], gjp: state.first[:gjp] }

    reply = conn(:post, @base <> @freq_list, data)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "delete friend request", state do
    confirm_relationship_endpoint(state, @freq_remove)
  end

  test "accept friend request", state do
    send_friend_request(state)

    data = %{ accountID: state.second[:id], targetAccountID: state.first[:id], gjp: state.second[:gjp] }
    reply = conn(:post, @base <> @friend_accept, data)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "list friends", state do
    data = %{ accountID: state.first[:id], gjp: state.first[:gjp] }

    reply = conn(:post, @base <> @friends_list, data)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "remove friend", state do
    confirm_relationship_endpoint(state, @friend_remove)
  end

  test "block user", state do
    confirm_relationship_endpoint(state, @user_block)
  end

  test "unblock user", state do
    confirm_relationship_endpoint(state, @user_unblock)
  end
end
