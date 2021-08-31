defmodule Api.UserTest do
  use ExUnit.Case
  use Plug.Test

  @options Router.init([])
  @register "/database/accounts/registerGJAccount.php"
  @login "/database/accounts/loginGJAccount.php"
  @user_search "/database/getGJUsers20.php"
  @user_get "/database/getGJUserInfo20.php"
  @content_type "application/x-www-form-urlencoded"

  test "Testing /getGJUserInfo20.php" do
    rs = Utils.random_string(16)
    params = %{ password: rs, userName: rs, email: rs <> "@gmail.com", confirmPassword: rs, confirmEmail: rs <> "@gmail.com" }

    # Register an account
    reply = conn(:post, @register, params)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    # Then get its ID
    reply = conn(:post, @login, params)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    id = reply.resp_body
      |> String.split(",")
      |> Enum.at(0)

    IO.inspect id

    # Get user by ID
    reply = conn(:post, @user_get, %{ targetAccountID: id })
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "Testing /getGJUsers20.php" do
    rs = Utils.random_string(16)
    params = %{ password: rs, userName: rs, email: rs <> "@gmail.com", confirmPassword: rs, confirmEmail: rs <> "@gmail.com" }

    # Register an account
    conn(:post, @register, params)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    # Search for user
    reply = conn(:post, @user_search, %{ str: params.userName })
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    #IO.inspect(reply.resp_body)

    assert reply.state   == :sent
    assert reply.status  == 200
  end
end
