defmodule Api.RewardsTest do
  use ExUnit.Case
  use Plug.Test

  @options Router.init([])
  @get_challenges "/database/getGJChallenges.php"
  @get_rewards "/database/getGJRewards.php"
  @content_type "application/x-www-form-urlencoded"

  test "challenges" do
    reply = conn(:post, @get_challenges)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end

  test "rewards" do
    reply = conn(:post, @get_rewards, %{ rewardType: "1", udid: Utils.random_udid() })
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    assert reply.state   == :sent
    assert reply.status  == 200
  end
end
