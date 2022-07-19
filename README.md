# Exstate
`Exstate` is a State Machine library for Elixir

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

## Usage
```elixir
import Exstate
alias Exstate.StateMachine

func = fn msg, inside ->
  IO.puts("#{msg} in #{inside}")
  {:ok, msg}
end

machine =
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
assert "created" == StateMachine.get_states(machine)

# Invoke transition
StateMachine.transition(machine, "created")

# state after transition
assert "customer_confirmed" == StateMachine.get_states(machine)
```