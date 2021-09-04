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

  def chk(values \\ [], key) when is_list(values) and is_atom(key) do
    salt = Application.get_env(:app, :salt)[key]

    :crypto.hash(:sha, values ++ [salt] |> Enum.join(""))
      |> Base.encode16
      |> xor(key)
      |> Base.encode64()
  end

  def xor(input, key) when is_binary(input) and is_atom(key) do
    key = Application.get_env(:app, :xor)[key] |> String.to_charlist()

    String.to_charlist(input)
      |> Enum.with_index
      |> Enum.map(
        fn { byte, idx } ->
          mod = rem(idx, length key)
          Bitwise.bxor(byte, key |> Enum.at(mod))
        end
      )
      |> List.to_string
  end

  def gjp(input, decode) when is_binary(input) do
    try do
      if decode do
        { :ok, decoded } = Base.decode64(input)
        xor(decoded, :authentication)
      else
        xor(input, :authentication) |> Base.encode64
      end
    rescue
      MatchError -> "[error]"
    end
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
