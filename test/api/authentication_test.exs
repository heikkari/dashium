defmodule Api.AuthenticationTest do
  use ExUnit.Case
  use Plug.Test

  @options Router.init([])
  @register "/database/accounts/registerGJAccount.php"
  @login "/database/accounts/loginGJAccount.php"
  @content_type "application/x-www-form-urlencoded"

  test "Testing authentication" do
    # Test registration
    rs = Utils.random_string(16)
    params = %{ password: rs, userName: rs, email: rs <> "@gmail.com", confirmPassword: rs, confirmEmail: rs <> "@gmail.com" }
    reply = conn(:post, @register, params)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200

    # Test login
    reply = conn(:post, @login, params)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end
end
