defmodule Utils do
  def is_field_missing(fields, map) do
    (Enum.map(fields, &(map[&1] === nil))
      |> Enum.filter(&(&1))
      |> length) > 0
  end

  def gen_id(), do: System.system_time(:millisecond) - Application.get_env(:app, :id_epoch)
end
