# Exstate
`Exstate` is a State Machine library for Elixir

##  Concepts
A finite state machine is a mathematical model of computation that describes the behavior of a system that can be in only one state at any given time. For example, let's say you can be represented by a state machine with a finite number (2) of states: asleep or awake. At any given time, you're either asleep or awake. It is impossible for you to be both asleep and awake at the same time, and it is impossible for you to be neither asleep nor awake.

Formally, finite state machines have five parts:
- A finite number of states
- A finite number of events
- An initial state
- A transition function that determines the next state given the current state and event
- A (possibly empty) set of final states

State refers to some finite, qualitative "mode" or "status" of a system being modeled by a state machine, and does not describe all the (possibly infinite) data related to that system. For example, water can be in 1 of 4 states: ice, liquid, gas, or plasma. However, the temperature of water can vary and its measurement is quantitative and infinite.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `exstate` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exstate, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/exstate>.

## Usage
```elixir
import Exstate
alias Exstate.StateMachine

func = fn msg, inside ->
  IO.puts("#{msg} in #{inside}")
  {:ok, msg}
end

state =
  %StateMachine.Machine{
    initial_state: "created",
    mapping: %{
      :created => %StateMachine.Transitions{
        target: "customer_confirmed",
        before: fn _ ->
          func.(:before_transition_, "created")
        end,
        callback: fn _ ->
          func.(:after_transition, "created")
        end
      },
      :customer_confirmed => %StateMachine.Transitions{
        target: "awaiting_payment",
        before: nil,
        callback: nil
      }
    },
    modifiable_states: MapSet.new(["created"])
  }
  |> StateMachine.new()

# state before transition
assert "created" == StateMachine.get_states(state)

# Invoke transition
StateMachine.transition(state, "created")

# state after transition
assert "customer_confirmed" == StateMachine.get_states(state)
```

More resources:
- [Finite-state machine](https://en.wikipedia.org/wiki/Finite-state_machine) article on Wikipedia
- [Understanding State Machines](https://www.freecodecamp.org/news/state-machines-basics-of-computer-science-d42855debc66/) by Mark Shead
- [A-Level Comp Sci: Finite State Machine](https://www.youtube.com/watch?v=4rNYAvsSkwk)