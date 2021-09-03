defmodule Utils do
  use Plug.Test

  @chars "qwertyuioasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890" |> String.split("")

  # Testing
  @options Router.init([])
  @register "/database/accounts/registerGJAccount.php"
  @login "/database/accounts/loginGJAccount.php"
  @content_type "application/x-www-form-urlencoded"

  def random_string(length) do
    Enum.reduce(1..length, [], fn _, acc -> [Enum.random(@chars) | acc] end)
      |> Enum.join("")
  end

  def is_field_missing(fields, map) do
    (Enum.map(fields, &(map[&1] === nil))
      |> Enum.filter(&(&1))
      |> length) > 0
  end

  def test_register() do
    rs = random_string(16)
    params = %{ password: rs, userName: rs, email: rs <> "@gmail.com", confirmPassword: rs, confirmEmail: rs <> "@gmail.com" }
    reply = conn(:post, @register, params)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    [ params, reply ]
  end

  def test_login(params) when is_map(params) do
    conn(:post, @login, params)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)
  end

  def gen_id(), do: System.system_time(:millisecond) - Application.get_env(:app, :id_epoch)
end
