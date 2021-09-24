defmodule Api.MiscellaneousTest do
  use ExUnit.Case
  use Plug.Test

  @options Router.init([])
  @artists_top "/database/getGJTopArtists.php"
  @info_song "/database/getGJSongInfo.php"
  @user_access_request "/database/requestUserAccess.php"
  @content_type "application/x-www-form-urlencoded"

  setup_all do
    # Register an account
    params = Utils.test_register() |> Enum.at(0)

    # Then get its ID
    reply = Utils.test_login(params)
    id = reply.resp_body |> String.split(",") |> Enum.at(0)

    [ params: params, id: id, gjp: Utils.gjp(params.password, false) ]
  end

  test "song info" do
    data = %{ "songID" => "1079735" }

    reply = conn(:post, @info_song, data)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "top artists" do
    reply = conn(:post, @artists_top)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "mod level", state do
    data = %{ accountID: state.id, gjp: state.gjp }

    reply = conn(:post, @user_access_request, data)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state     == :sent
    assert reply.status    == 200
    assert reply.resp_body == "-1"
  end
end
