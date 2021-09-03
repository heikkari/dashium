defmodule Api.AuthenticationTest do
  use ExUnit.Case
  use Plug.Test

  test "Testing authentication" do
    # Test registration
    [params | [ reply | _ ] ] = Utils.test_register()
    assert reply.state   == :sent
    assert reply.status  == 200

    # Test login
    reply = Utils.test_login(params)
    assert reply.state   == :sent
    assert reply.status  == 200
  end
end
