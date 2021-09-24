defmodule Utils do
  use Plug.Test

  # Testing
  @options Router.init([])
  @register "/database/accounts/registerGJAccount.php"
  @login "/database/accounts/loginGJAccount.php"
  @content_type "application/x-www-form-urlencoded"

  @spec random_string(integer) :: binary
  def random_string(length) do
    :crypto.strong_rand_bytes(length / 2 |> Kernel.trunc)
      |> Base.encode16
      |> String.downcase
  end

  @spec random_udid :: binary
  def random_udid() do
    Enum.map([8, 4, 4, 4, 12], &(random_string(&1))) |> Enum.join("-")
  end

  @spec chk(list, atom) :: binary
  def chk(values \\ [], key) when is_list(values) and is_atom(key) do
    salt = Application.get_env(:app, :salt)[key]

    :crypto.hash(:sha, values ++ [salt] |> Enum.join(""))
      |> Base.encode16
      |> xor(key)
      |> Base.encode64()
  end

  @spec xor(binary, atom) :: binary
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

  @spec gjp(binary, boolean) :: binary
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

  @spec is_field_missing(map, map) :: boolean
  def is_field_missing(fields, map) do
    (Enum.map(fields, &(map[&1] === nil))
      |> Enum.filter(&(&1))
      |> length) > 0
  end

  @spec test_register :: list
  def test_register() do
    rs = random_string(16)
    params = %{ password: rs, userName: rs, email: rs <> "@gmail.com", confirmPassword: rs, confirmEmail: rs <> "@gmail.com" }
    reply = conn(:post, @register, params)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)

    [ params, reply ]
  end

  @spec test_login(map) :: Plug.Conn.t()
  def test_login(params) when is_map(params) do
    conn(:post, @login, params)
      |> put_req_header("content-type", @content_type)
      |> Router.call(@options)
  end

  @spec gen_id :: integer
  def gen_id(), do: System.system_time(:millisecond) - Application.get_env(:app, :id_epoch)

  @spec id_to_unix(integer) :: integer
  def id_to_unix(id) when is_integer(id) do
    id + Application.get_env(:app, :id_epoch)
  end

  def song_info(id) when is_integer(id) do
    song_server = Application.get_env(:app, :song_server)
    response = :httpc.request(:get, {"#{song_server}#{id}", []}, [], [])

    if response |> elem(0) === :error do
      { :error, :couldnt_connect_to_server }
    else
      { :ok, document } = Floki.parse_document(response |> elem(1) |> elem(2))

      # Get song name & artist
      [ { _, _, [ song | _ ] } | _ ] = Floki.find(document, "title")
      [ { _, _, [ elem | _ ] } | _ ] = Floki.find(document, "h4")
      [ { "a", attributes, _ } | _ ] = Floki.find(document, ".icon-download")

      # ---
      { _, _, [ artist | _ ] } = elem
      url = Enum.into(attributes, %{})["href"]

      # Get song file size
      headers = :httpc.request(:head, { url, [] }, [], []) |> elem(1) |> elem(1) |> Enum.into(%{})
      size_mb = (headers['content-length'] |> List.to_string |> String.to_integer) / 1048576 |> Float.ceil(2)

      { :ok, %{ song: song, id: id, artist: artist, size: size_mb, url: url } }
    end
  end
end
