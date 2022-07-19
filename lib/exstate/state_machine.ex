defmodule Exstate.StateMachine do
  @moduledoc """
  Exstate is split into 3 parts:
    - `Machine`
    - `Context`
    - `Transitions`
  
  # Concepts
  A finite state machine is a mathematical model of computation that describes the behavior of a system that can be in only one state at any given time. For example, let's say you can be represented by a state machine with a finite number (2) of states: asleep or awake. At any given time, you're either asleep or awake. It is impossible for you to be both asleep and awake at the same time, and it is impossible for you to be neither asleep nor awake.
  
  Formally, finite state machines have five parts:
  - A finite number of states
  - A finite number of events
  - An initial state
  - A transition function that determines the next state given the current state and event
  - A (possibly empty) set of final states
  
  State refers to some finite, qualitative "mode" or "status" of a system being modeled by a state machine, and does not describe all the (possibly infinite) data related to that system. For example, water can be in 1 of 4 states: ice, liquid, gas, or plasma. However, the temperature of water can vary and its measurement is quantitative and infinite.
  
  """

  @enforce_keys [:states, :pid]
  defstruct states: nil,
            pid: nil,
            external: nil

  use TypeStruct
  use GenServer
  alias Exstate.Utils, as: U

  require Logger

  defstruct(Machine,
    initial_state: String.t(),
    mapping: map(),
    modifiable_states: MapSet.t()
  )

  @type t :: %__MODULE__{
          states: Machine.t(),
          pid: pid(),
          external: term()
        }

  defstruct(Context,
    pid: pid(),
    event: term(),
    # ^ The event that caused the transition
    access_time: term(),
    state: term(),
    # ^ The resolved machine state, after transition
    instance: term()
    # ^ Any external value you want to pass it
  )

  defstruct(Transitions,
    target: String.t(),
    before: fun() | nil,
    callback: fun() | nil
  )

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
    Construct a new
  """
  @spec new(Machine.t(), term()) :: t()
  def new(states, external \\ nil) do
    unless is_nil(states) do
      {:ok, pid} = GenServer.start_link(__MODULE__, states, name: __MODULE__)
      %__MODULE__{states: states, pid: pid, external: external}
    end
  end

  @spec can_transition?(t(), String.t() | atom()) :: boolean()
  def can_transition?(machine, event) do
    map_set = MapSet.new(machine.states.mapping)

    unless U.nil_or_empty?(map_set) do
      parent_keys = U.get_mapset_keys(map_set)

      # Support nested dynamic keys (e.g "created.customer_confirmed")
      # Able to use atom for event,
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

  @spec modifiable?(t(), term()) :: boolean()
  def modifiable?(machine, current_state) do
    modifiable_statuses =
      machine.states.modifiable_states
      |> MapSet.new(fn v -> v end)

    MapSet.member?(modifiable_statuses, current_state)
  end

  @spec transition(t(), String.t() | atom()) :: term()
  def transition(machine, event) do
    if not can_transition?(machine, event) do
      # raise ArgumentError, need validate on runtime?
      {:err, "Event '#{event}' does not exist!"}
    else
      e = U.to_atom(event)
      map_set = MapSet.new(machine.states.mapping)

      [head_ev_key | tail_ev_key] =
        case event do
          evt when is_atom(evt) ->
            [Atom.to_string(evt)]

          evt when is_binary(evt) ->
            String.split(event, ".")

          _ ->
            nil
        end

      parent_key_accessor = head_ev_key
      second_key_accessor = Enum.find(tail_ev_key, fn v -> v end)

      unless U.nil_or_empty?(map_set) do
        list_entry = MapSet.to_list(map_set)

        # Validate type of mapping
        if not valid_map?(list_entry) do
          raise ArgumentError, "Error in ':mapping', all field must within same type!"
        else
          transition_entry =
            if not has_nested_mapping?(list_entry) do
              list_entry
              |> Enum.map(fn {k, val} -> if(match?(^k, e), do: val) end)
              |> Enum.filter(fn v -> not is_nil(v) end)
            else
              parent_val =
                list_entry
                |> Enum.filter(fn {k, _val} ->
                  match?(^k, String.to_existing_atom(parent_key_accessor))
                end)
                |> Enum.map(fn {_k, v} -> v end)

              # !nil => nested key
              if(is_nil(second_key_accessor),
                do: parent_val,
                else:
                  get_in(parent_val, [
                    Access.all(),
                    Access.key!(String.to_existing_atom(second_key_accessor))
                  ])
              )
            end

          # before transition
          before_arg = access_key_of_struct(transition_entry, :before)
          new_state = access_key_of_struct(transition_entry, :target)

          # not yet evaluated
          apply_transition = fn ->
            # state transition happens here
            transition_entry
            |> access_key_of_struct(:target)
            |> set_states(machine)

            # after transition
            transition_entry
            |> access_key_of_struct(:callback)
            |> async_call_arg_function!(
              machine,
              %{
                state: new_state,
                event: event
              }
            )

            {:ok, :done}
          end

          # next transition will run if prev process not contains error
          case before_arg do
            argument when is_nil(argument) ->
              apply_transition.()

            argument when is_function(argument) ->
              argument
              |> async_call_arg_function!(machine)
              |> handle_tuple_result!(apply_transition)
          end
        end
      end
    end
  end

  @doc false
  def init(state) do
    {:ok, state}
  end

  defp set_states(new_state, machine) do
    GenServer.call(machine.pid, {:set_states, new_state})
  end

  def get_states(machine) do
    GenServer.call(machine.pid, :get_states)
  end

  # handle_call(message, from_pid, state) -> {:reply, response, new_state}
  # see http://elixir-lang.org/docs/v1.0/elixir/GenServer.html
  def handle_call({:set_states, new_value}, _from, state) do
    try do
      new_state = Map.put(state, :initial_state, new_value)
      {:reply, state, new_state}
    rescue
      Protocol.UndefinedError -> {:reply, :err, nil}
    end
  end

  def handle_call(:get_states, _from, state) do
    try do
      {:reply, state.initial_state, state}
    rescue
      Protocol.UndefinedError -> {:reply, :err, nil}
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

  @spec valid_map?(list()) :: boolean()
  defp valid_map?(list) do
    members = [
      Enum.all?(list, fn {_k, v} -> is_transitions_struct(v) end),
      Enum.all?(list, fn {_k, v} -> not is_transitions_struct(v) end)
    ]

    Enum.any?(members)
  end

  @spec access_key_of_struct(struct(), atom()) :: struct()
  defp access_key_of_struct(entry, key) do
    entry
    |> get_in([
      Access.all(),
      Access.key!(key)
    ])
    |> Enum.find(fn v -> v end)
  end

  @spec get_keys_of_struct(String.t(), term(), nonempty_list()) :: list()
  defp get_keys_of_struct(key, val_of_struct, list) do
    val_of_struct
    |> Map.keys()
    |> Enum.map(fn k2 ->
      if has_nested_mapping?(list) do
        "#{key}.#{Atom.to_string(k2)}"
      else
        Atom.to_string(key)
      end
    end)
    |> Enum.uniq()
  end

  @spec get_all_keys(nonempty_list()) :: list()
  defp get_all_keys(list) do
    results =
      Enum.flat_map(
        list,
        fn {k, value} -> get_keys_of_struct(k, value, list) end
      )

    # Returns default ["parent_key"], if nested, ["parent_key.children_key"]
    if(not has_nested_mapping?(list),
      do: results,
      else:
        list
        |> Enum.flat_map(fn {k2, _v} -> Enum.concat(results, [Atom.to_string(k2)]) end)
        |> Enum.uniq()
    )
  end

  @spec handle_tuple_result!(term(), fun()) :: term()
  defp handle_tuple_result!(value, func) do
    case value do
      {:ok} ->
        func.()

      {:ok, _} ->
        func.()

      {:error, reason} ->
        Logger.error("Before transition error: #{reason}")
        {:error, :bad, reason}

      _ ->
        :nothing
    end
  end

  @spec async_call_arg_function!(fun(), Machine.t(), term() | nil) :: fun()
  defp async_call_arg_function!(f, machine, context \\ nil) do
    call_func = fn ->
      if is_function(f) do
        next_state = unless(is_nil(context), do: Map.get(context, :state))
        next_event = unless(is_nil(context), do: Map.get(context, :event))

        func =
          f.(%Context{
            pid: machine.pid,
            event: next_event,
            access_time: :os.system_time(),
            state: next_state,
            instance: machine.external
          })

        if not is_tuple(func) or not U.tuple_result?(func) do
          raise RuntimeError, "Return type must tuple, e.g {:ok | :err | :error, ..}"
        else
          func
        end
      end
    end

    # HACK: Working properly
    results =
      Task.async(fn ->
        try do
          call_func.()
        rescue
          _ -> :failed
        end
      end)

    Task.await(results)
  end

  @spec has_nested_mapping?(nonempty_list()) :: boolean()
  defp has_nested_mapping?(list) do
    transition_keys =
      list
      |> get_in([Access.all()])
      |> Enum.flat_map(fn {_k, v} -> Map.keys(v) end)
      |> Enum.map(&Atom.to_string/1)

    required_key = :target
    not Enum.member?(transition_keys, Atom.to_string(required_key))
  end
end
