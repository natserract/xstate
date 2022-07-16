defmodule Exstate do
  @moduledoc """
  Documentation for `Exstate`.
  """

  alias Exstate.StateMachine

  # use Exstate.StateMachine,
  #   deps: [

  #   ]
  # use Exstate.StateMachine

  @doc """
  Hello world.

  ## Examples

      iex> Exstate.hello()
      :world

  """
  @spec hello :: Exstate.StateMachine.t()
  def hello do
    machine =
      StateMachine.new(%StateMachine{
        states: %StateMachine.State{
          initial_state: "s",
          mapping: %{:a => 1, 2 => :b},
          modifiable_states: MapSet.new([3, 3, 3, 2, 2, 1])
        }
      })

    machine
  end
end
