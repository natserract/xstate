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
      {:ok, pid} = GenServer.start_link(__MODULE__, states, [])
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
        ev when is_binary(ev) ->
          event_keys =
            ev
            |> String.split(".")
            |> Enum.map(&String.to_existing_atom/1)

          atomic_keys =
            map_set
            |> MapSet.to_list()
            |> merge_all_keys(parent_keys)

          Enum.any?(event_keys, fn k ->
            Enum.member?(
              atomic_keys,
              Atom.to_string(k)
            )
          end)

        ev when is_atom(ev) ->
          Enum.member?(parent_keys, Atom.to_string(ev))
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

        # Validate return of maps is same or not
        if is_valid_map_return(list_entry) do
          event_keys =
            event
            |> String.split(".")
            |> Enum.map(&String.to_existing_atom/1)

          [_ | tail] = event_keys

          is_has_nested =
            list_entry
            |> Enum.map(fn {_k, v} -> v end)
            |> Enum.all?(fn v -> not is_transitions_struct(v) end)

          transition_entry =
            if is_has_nested do
              values = Enum.map(list_entry, fn {_k, v} -> v end)

              values
              |> get_in([Access.all(), Access.key(Enum.find(tail, fn v -> v end))])
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

  def set_states(machine, new_data) do
    GenServer.call(machine.pid, {:set_states, new_data})
  end

  def get_states(machine) do
    # :sys.get_state(machine.pid)
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
    {:reply, state, state}
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

  @spec merge_all_keys(nonempty_list(), list()) :: list()
  defp merge_all_keys(list, parent_keys) do
    list
    |> Enum.flat_map(fn {_k, v} -> Map.keys(v) end)
    |> Enum.map(&Atom.to_string/1)
    |> Enum.concat(parent_keys)
  end
end
