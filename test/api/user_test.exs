defmodule Api.UserTest do
  use ExUnit.Case
  use Plug.Test

  @options Router.init([])
  @user_search "/database/getGJUsers20.php"
  @user_get "/database/getGJUserInfo20.php"
  @user_update "/database/updateGJAccSettings20.php"
  @content_type "application/x-www-form-urlencoded"

  setup_all do
    # Register an account
    params = Utils.test_register() |> Enum.at(0)

    # Then get its ID
    reply = Utils.test_login(params)
    id = reply.resp_body |> String.split(",") |> Enum.at(0)

    { :ok, params: params, id: id }
  end

  test "Testing /getGJUserInfo20.php", state do
    # Get user by ID
    reply = conn(:post, @user_get, %{ targetAccountID: state.id })
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "Testing /getGJUsers20.php", state do
    # Search for user
    reply = conn(:post, @user_search, %{ str: state.params.userName })
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "Testing /updateGJAccSettings20.php", state do
    # Update the user
    gjp = Utils.gjp(state.params.password, false)
    reply = conn(:post, @user_update, %{ accountID: state.id, gjp: gjp, mS: 1 })
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end
end
