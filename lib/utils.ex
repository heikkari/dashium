defmodule Utils do
  @chars "qwertyuioasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890" |> String.split("")

  def random_string(length) do
    Enum.reduce(1..length, [], fn _, acc -> [Enum.random(@chars) | acc] end)
      |> Enum.join("")
  end

  def is_field_missing(fields, map) do
    (Enum.map(fields, &(map[&1] === nil))
      |> Enum.filter(&(&1))
      |> length) > 0
  end

  def gen_id(), do: System.system_time(:millisecond) - Application.get_env(:app, :id_epoch)
end
