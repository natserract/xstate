defmodule Exstate.StateMachine do
  @moduledoc """
  Blablac
  """
  @enforce_keys [:states]
  defstruct states: nil,
            transitions: nil

  use TypeStruct
  alias Exstate.Utils, as: U

  defstruct(Machine,
    initial_state: String.t(),
    mapping: map(),
    modifiable_states: MapSet.t()
  )

  @type t :: %__MODULE__{
          states: Machine.t()
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
    predicate: String.t() | nil,
    before: action_t(),
    callback: action_t()
  )

  @doc """
    Construct a new
  """
  @spec new(Machine.t()) :: t()
  def new(states) do
    unless is_nil(states) do
      %__MODULE__{states: states}
    end
  end

  @spec can_transition(t(), String.t() | atom()) :: boolean()
  def can_transition(val, event) do
    map_set = MapSet.new(val.states.mapping)

    unless U.is_nil_or_empty(map_set) do
      keys = U.get_mapset_keys(map_set)

      Enum.member?(
        keys,
        U.to_atom(event)
      )
    end
  end

  @spec modifiable(t(), String.t() | atom()) :: boolean()
  def modifiable(val, event) do
    modifiable_statuses = val.states.modifiable_states |> MapSet.new(&U.to_atom/1)

    unless U.is_nil_or_empty(modifiable_statuses) do
      MapSet.member?(modifiable_statuses, U.to_atom(event))
    end
  end
end
