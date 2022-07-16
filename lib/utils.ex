defmodule Exstate.Utils do
  @moduledoc false
  @spec get_in_struct(struct(), nonempty_list(atom())) :: term()
  def get_in_struct(struct, location) do
    locator = Enum.map(location, &Access.key/1)
    get_in(struct, locator)
  end

  @spec is_nil_or_empty(nil | map()) :: boolean()
  def is_nil_or_empty(val) do
    case val do
      v when is_map(v) -> MapSet.size(v) == 0
      v when is_nil(v) -> true
    end
  end

  @spec get_mapset_keys(MapSet.t()) :: list()
  def get_mapset_keys(map_set) do
    map_set
    |> MapSet.to_list()
    |> Enum.map(fn {k, _v} -> to_atom(k) end)
  end

  @spec to_atom(String.t() | atom()) :: atom()
  def to_atom(event) do
    cond do
      is_binary(event) -> String.to_atom(event)
      is_atom(event) -> event
    end
  end
end