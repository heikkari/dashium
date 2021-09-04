defmodule Api.UserTest do
  use ExUnit.Case
  use Plug.Test

  @options Router.init([])
  @user_search "/database/getGJUsers20.php"
  @user_info "/database/getGJUserInfo20.php"
  @user_update "/database/updateGJAccSettings20.php"
  @user_score "/database/updateGJUserScore22.php"
  @content_type "application/x-www-form-urlencoded"

  setup_all do
    # Register an account
    params = Utils.test_register() |> Enum.at(0)

    # Then get its ID
    reply = Utils.test_login(params)
    id = reply.resp_body |> String.split(",") |> Enum.at(0)

    { :ok, params: params, id: id, gjp: Utils.gjp(params.password, false) }
  end

  test "Testing /getGJUserInfo20.php", state do
    # Get user by ID
    reply = conn(:post, @user_info, %{ targetAccountID: state.id })
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
    reply = conn(:post, @user_update, %{ accountID: state.id, gjp: state.gjp, mS: 1 })
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "Testing /updateGJUserScore22.php", state do
    fields = [
      accountID: state.id,
      userCoins: 3, demons: 2, stars: 40,
      coins: 3, iconType: 0, icon: 0, diamonds: 5,
      accIcon: 0, accShip: 0, accBall: 0, accBird: 0,
      accDart: 0, accRobot: 0, accGlow: 0, accSpider: 0,
      accExplosion: 0
    ]

    chk = Utils.chk(Enum.map(fields, fn {_, v} -> v end), :user_profile)
    fields = fields ++ [ seed2: chk, gjp: state.gjp ]

    reply = conn(:post, @user_score, fields)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end
end
