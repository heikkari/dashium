defmodule Api.RelationshipsTest do
  use ExUnit.Case, async: false
  use Plug.Test

  @options Router.init([])
  @friend_add "/database/uploadGJFriendRequest20.php"
  @friend_accept "/database/acceptGJFriendRequest20.php"
  @friend_remove "/database/removeGJFriend20.php"
  @friends_list "/database/getGJUserList20.php"
  @user_block "/database/blockGJUser20.php"
  @user_unblock "/database/unblockGJUser20.php"
  @freq_remove "/database/deleteGJFriendRequests20.php"
  @freq_list "/database/getGJFriendRequests20.php"
  @content_type "application/x-www-form-urlencoded"

  @spec confirm_relationship_endpoint(any, binary) :: none
  def confirm_relationship_endpoint(state, endpoint) when is_binary(endpoint) do
    data = %{ accountID: state.first[:id], targetAccountID: state.second[:id], gjp: state.first[:gjp] }

    reply = conn(:post, endpoint, data)
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

    reply = conn(:post, @freq_list, data)
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
    confirm_relationship_endpoint(state, @friend_accept)
  end

  test "list friends", state do
    data = %{ accountID: state.first[:id], gjp: state.first[:gjp] }

    reply = conn(:post, @friends_list, data)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "block user", state do
    confirm_relationship_endpoint(state, @user_block)
  end

  test "unblock user", state do
    confirm_relationship_endpoint(state, @user_unblock)
  end

  test "remove friend", state do
    confirm_relationship_endpoint(state, @friend_remove)
  end
end
