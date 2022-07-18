defmodule Exstate.Utils do
  @moduledoc false
  @spec get_in_struct(struct(), nonempty_list(atom())) :: term()
  def get_in_struct(struct, location) do
    locator = Enum.map(location, &Access.key/1)
    get_in(struct, locator)
  end

  @spec nil_or_empty?(nil | map()) :: boolean()
  def nil_or_empty?(val) do
    case val do
      v when is_map(v) -> MapSet.size(v) == 0
      v when is_nil(v) -> true
    end
  end

  @spec get_mapset_keys(MapSet.t()) :: list()
  def get_mapset_keys(map_set) do
    map_set
    |> MapSet.to_list()
    |> Enum.map(fn {k, _v} -> Atom.to_string(k) end)
  end

  @spec to_atom(String.t() | atom()) :: atom()
  def to_atom(event) do
    cond do
      # use existing_atom?
      is_binary(event) -> String.to_atom(event)
      is_atom(event) -> event
    end
  end

  @spec capture_link(fun()) :: term()
  def capture_link(callback) do
    Process.flag(:trap_exit, true)
    pid = spawn_link(callback)

    receive do
      {:EXIT, ^pid, :normal} -> :ok
      {:EXIT, ^pid, reason} -> {:error, reason}
    end
  end

  @spec tuple_result?(tuple()) :: boolean()
  def tuple_result?(tuple) do
    keys =
      tuple
      |> Tuple.to_list()
      |> Enum.find(fn v -> v end)
      |> Atom.to_string()

    # Only accept format: {:ok, :err, :error}
    keys == "ok" or
      keys == "error" or
      keys == "err"
  end
end
