defmodule Routes.Miscellaneous do
  alias Models.User, as: User

  @spec mod(map) :: { 200 | 400 | 500, binary }
  defp mod(params) when is_map(params) do
    if Utils.is_field_missing ["accountID"], params do
      { 401, "-1" }
    else
      try do
        user = User.get(params["accountID"] |> String.to_integer())
        { 200, (if user.mod_level > 0, do: "1", else: "-1") }
      rescue
        _ -> { 500, "-1" }
      end
    end
  end

  @spec top_artists(map) :: { 200 | 500, binary }
  defp top_artists(params) when is_map(params) do
    try do
      url = Application.get_env(:app, :top_artists)
      request = {url, [], 'application/x-www-form-urlencoded', 'secret=Wmfd2893gb7&page=1' }
      { 200, :httpc.request(:post, request, [], []) |> elem(1) |> elem(2) |> List.to_string }
    rescue
      _ -> { 500, "-1" }
    end
  end

  @spec song_info(map) :: { 200 | 400 | 500, binary }
  defp song_info(params) when is_map(params) do
    if Utils.is_field_missing ["songID"], params do
      { 400, "-1" }
    else
      try do
        song_id = params["songID"] |> String.to_integer
        { :ok, info } = Utils.song_info(song_id)
        parts = [ 1, song_id, 2, info.song, 3, "", 4, info.artist, 5, info.size, 6, "", 7, "", 10, info.url ]
        { 200, parts |> Enum.join("~|~") }
      rescue
        _ -> { 500, "-1" }
      end
    end
  end

  @spec list :: list
  def list() do
    [
      "getAccountURL.php",
      "getGJSongInfo.php",
      "getGJTopArtists.php",
      "getSaveData.php",
      "requestUserAccess.php"
    ]
  end

  @spec exec(Plug.Conn.t(), binary) :: { integer, binary }
  def exec(conn, route) when is_binary(route) do
    case route do
      "getAccountURL.php" -> { 200, Application.get_env(:app, :save_server) }
      "getGJSongInfo.php" -> song_info(conn.params)
      "getGJTopArtists.php" -> top_artists(conn.params)
      "getSaveData.php" -> { 200, Utils.random_string(32) |> Base.encode64 }
      "requestUserAccess.php" -> mod(conn.params)
    end
  end
end
