defmodule Api.ApiRoutesTest do
  use ExUnit.Case
  use Plug.Test

  @base "/api"
  @options Router.init([])

  test "Getting data" do
    conn =
      :get |> conn("#{@base}/", %{}) |> Router.call(@options)

    assert conn.state   == :sent
    assert conn.status  == 200
  end
end
