defmodule Api.RewardsTest do
  use ExUnit.Case
  use Plug.Test

  @options Router.init([])
  @base "/database/"
  @get_challenges "getGJChallenges.php"
  @get_rewards "getGJRewards.php"
  @content_type "application/x-www-form-urlencoded"

  test "challenges" do
    reply = conn(:post, @base <> @get_challenges)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "rewards" do
    query = %{ rewardType: "1", udid: Utils.random_udid() }

    reply = conn(:post, @base <> @get_rewards, query)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end
end
