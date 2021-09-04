defmodule Plugs.Validator do
  import Plug.Conn
  alias Models.Account, as: Account

  def init(options) do
    options
  end

  def validate(conn) do
    accepted_chars = Application.get_env(:app, :accepted_chars)

    if Enum.member?(
      (Enum.flat_map(conn.params, fn tuple ->
        Enum.flat_map(tuple |> Tuple.to_list, fn value ->
          Enum.map(value |> Enum.to_list, &(String.contains? accepted_chars, &1))
        end)
      end)),
      false
    ) do
      # Sent if the parameters don't only contain accepted characters
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(400, "-1")
      |> halt
    else
      conn
    end
  end

  def call(conn, _) do
    conn |> validate
  end
end
