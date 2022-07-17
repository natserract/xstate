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
            case event do
              evt when is_atom(evt) -> [Atom.to_string(evt)]
              evt when is_binary(evt) -> event |> String.split(".")
              _ -> nil
            end

          [head_ev_key | tail_ev_key] = event_keys
          parent_key_accessor = head_ev_key
          second_key_accessor = Enum.find(tail_ev_key, fn v -> v end)

          transition_entry =
            if has_nested_mapping(list_entry) do
              parent_val =
                list_entry
                |> Enum.filter(fn {k, _val} ->
                  match?(^k, String.to_existing_atom(parent_key_accessor))
                end)
                |> Enum.map(fn {_k, v} -> v end)

              # !Nil => nested key
              if not is_nil(second_key_accessor) do
                get_in(parent_val, [
                  Access.all(),
                  Access.key!(String.to_existing_atom(second_key_accessor))
                ])
              else
                parent_val
              end
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
          if has_nested_mapping(list) do
            "#{k}.#{Atom.to_string(k2)}"
          else
            Atom.to_string(k)
          end
        end)
        |> Enum.uniq()
      end)

    # Nested behaviour
    if has_nested_mapping(list) do
      list
      |> Enum.flat_map(fn {k2, _v} -> Enum.concat(results, [Atom.to_string(k2)]) end)
      |> Enum.uniq()
    else
      results
    end
  end

  @spec has_nested_mapping(nonempty_list()) :: boolean()
  defp has_nested_mapping(list) do
    transition_keys =
      list
      |> get_in([Access.all()])
      |> Enum.flat_map(fn {_k, v} -> Map.keys(v) end)
      |> Enum.map(&Atom.to_string/1)

    required_key = :target
    not Enum.member?(transition_keys, Atom.to_string(required_key))
  end
end
