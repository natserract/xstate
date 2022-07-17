defmodule Exstate.StateMachine do
  @moduledoc """
  Blablac
  """
  @enforce_keys [:states]
  defstruct states: nil,
            pid: nil

  use TypeStruct
  use GenServer
  alias Exstate.Utils, as: U

  defstruct(Machine,
    initial_state: String.t(),
    mapping: map(),
    modifiable_states: MapSet.t()
  )

  @type t :: %__MODULE__{
          states: Machine.t(),
          pid: pid()
        }

  @typedoc """
    Arguments
    -> `context`: the current machine context
    -> `event`: The event that caused the transition
    -> `state`: The resolved machine state, after transition
  """
  @type action_t :: fun(Machine.t()) | nil

  defstruct(Transitions,
    target: String.t(),
    before: action_t(),
    callback: action_t()
  )

  # Context:
  # category: nested,

  # TODO
  # - validate initial state <-> target?
  # - Support nested transitions, like: 'walk.in'

  @doc """
    Construct a new
  """
  @spec new(Machine.t()) :: t()
  def new(states) do
    unless is_nil(states) do
      {:ok, pid} = GenServer.start_link(__MODULE__, states, name: __MODULE__)
      %__MODULE__{states: states, pid: pid}
    end
  end

  @spec can_transition(t(), String.t() | atom()) :: boolean()
  def can_transition(machine, event) do
    map_set = MapSet.new(machine.states.mapping)

    unless U.is_nil_or_empty(map_set) do
      parent_keys = U.get_mapset_keys(map_set)

      # Support nested dynamic keys (e.g "created.customer_confirmed")
      # Able to use atom for event, our will parsed all atom event to binary
      case event do
        evt when is_binary(evt) ->
          atomic_keys =
            map_set
            |> MapSet.to_list()
            |> get_all_keys()

          Enum.member?(atomic_keys, evt)

        evt when is_atom(evt) ->
          Enum.member?(parent_keys, Atom.to_string(evt))
      end
    end
  end

  @spec modifiable(t(), String.t() | atom()) :: boolean()
  def modifiable(machine, event) do
    modifiable_statuses = machine.states.modifiable_states |> MapSet.new(&U.to_atom/1)

    unless U.is_nil_or_empty(modifiable_statuses) do
      MapSet.member?(modifiable_statuses, U.to_atom(event))
    end
  end

  @spec transition(t(), String.t() | atom()) :: term()
  def transition(machine, event) do
    if not can_transition(machine, event) do
      # raise ArgumentError, need validate on runtime?
      {:err, "Event '#{event}' does not exist!"}
    else
      e = U.to_atom(event)
      map_set = MapSet.new(machine.states.mapping)

      unless U.is_nil_or_empty(map_set) do
        list_entry = map_set |> MapSet.to_list()

        ## Validate return of maps is same or not
        if is_valid_map_return(list_entry) do
          event_keys =
            event
            |> String.split(".")
            |> Enum.map(&String.to_existing_atom/1)

          [_ | tail_ev] = event_keys

          is_has_nested =
            list_entry
            |> Enum.map(fn {_k, v} -> v end)
            |> Enum.all?(fn v -> not is_transitions_struct(v) end)

          transition_entry =
            if is_has_nested do
              values = Enum.map(list_entry, fn {_k, v} -> v end)

              ## Only support 2 level access, [parent][children]
              values
              |> get_in([Access.all(), Access.key(Enum.find(tail_ev, fn v -> v end))])
              |> Enum.filter(fn v -> not is_nil(v) end)
            else
              list_entry
              |> Enum.map(fn {k, val} -> if match?(^k, e), do: val end)
              |> Enum.filter(fn v -> not is_nil(v) end)
            end

          transition_entry
        else
          raise ArgumentError, "Error in ':mapping', all field must within same type!"
        end
      end
    end
  end

  # initiating state
  def init(state) do
    {:ok, state}
  end

  def set_states(machine, new_data) do
    GenServer.call(machine.pid, {:set_states, new_data})
  end

  def get_states(machine) do
    GenServer.call(machine.pid, :get_states)
  end

  # handle_call(message, from_pid, state) -> {:reply, response, new_state}
  # see http://elixir-lang.org/docs/v1.0/elixir/GenServer.html
  def handle_call({:set_states, new_data}, _from, state) do
    try do
      {:reply, state, new_data}
    rescue
      Protocol.UndefinedError -> {:reply, :err, state}
    end
  end

  def handle_call(:get_states, _from, state) do
    try do
      {:reply, state, state}
    rescue
      Protocol.UndefinedError -> {:reply, :err, state}
    end
  end

  @spec is_transitions_struct(struct()) :: boolean()
  defp is_transitions_struct(val) do
    case val do
      v when is_struct(v, Transitions) -> true
      v when is_struct(v) -> true
      _ -> false
    end
  end

  @spec is_valid_map_return(list()) :: boolean()
  defp is_valid_map_return(list) do
    members = [
      Enum.all?(list, fn {_k, v} -> is_transitions_struct(v) end),
      Enum.all?(list, fn {_k, v} -> not is_transitions_struct(v) end)
    ]

    Enum.any?(members)
  end

  # @returns default ["parent_key"],
  # if nested, ["parent_key.children_key"]
  @spec get_all_keys(nonempty_list()) :: list()
  defp get_all_keys(list) do
    results =
      list
      |> Enum.flat_map(fn {k, value} ->
        value
        |> Map.keys()
        |> Enum.map(fn k2 ->
          if not has_transition_key(list) do
            "#{k}.#{Atom.to_string(k2)}"
          else
            Atom.to_string(k)
          end
        end)
        |> Enum.uniq()
      end)

    if not has_transition_key(list) do
      list
      |> Enum.flat_map(fn {k2, _v} -> Enum.concat(results, [Atom.to_string(k2)]) end)
      |> Enum.uniq()
    else
      results
    end
  end

  @spec has_transition_key(nonempty_list()) :: boolean()
  defp has_transition_key(list) do
    transition_keys =
      list
      |> get_in([Access.all()])
      |> Enum.flat_map(fn {_k, v} -> Map.keys(v) end)
      |> Enum.map(&Atom.to_string/1)

    required_key = :target
    Enum.member?(transition_keys, Atom.to_string(required_key))
  end
end
