defmodule Exstate.StateMachine do
  @moduledoc """
  Blablac
  """
  @enforce_keys [:states]
  defstruct states: nil

  use TypeStruct

  defstruct(State,
    initial_state: String.t(),
    mapping: map(),
    modifiable_states: MapSet.t()
  )

  @type t :: %__MODULE__{states: State.t()}

  @doc """
    Construct a new
  """
  @spec new(t()) :: t()
  def new(states) do
    %__MODULE__{
      states: states
    }
  end

  @spec init_state(State.t()) :: State.t()
  def init_state(state), do: state

  @spec create(String.t(), StateMachine.t()) :: any
  def create(name, data) do
  end
end
