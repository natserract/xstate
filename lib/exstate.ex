defmodule Exstate do
  alias Exstate.StateMachine
  require Logger

  @moduledoc ~S"""
  `Exstate` is Elixir state machine library

  Top-level `use` aliases
  In almost all cases, you want:
      use Exceptional
  If you only want the operators:
      use Exceptional, only: :operators
  If you only want named functions:
      use Exceptional, only: :named_functions
  If you like to live extremely dangerously. This is _not recommended_.
  Please be certain that you want to override the standard lib before using.
      use Exceptional, include: :overload_pipe
  """

  # defmacro __using__(opts \\ []) do
  #   quote bind_quoted: [opts: opts] do
  #     use Exstate.StateMachine, opts
  #   end
  # end

  init_machine =
    StateMachine.new(%StateMachine.Machine{
      initial_state: "created",
      mapping: %{
        # TODO: Documenting layout of mapping
        :created => %{
          :confirmed_by_customer => %StateMachine.Transitions{
            target: "customer_confirmed",
            before: fn context ->
              try do
                # throw(:error)
                Process.sleep(2000)
                # IO.inspect(context)
                IO.puts("Before")
                {:ok, "Before"}
              catch
                _, reason -> {:error, reason}
              end
            end,
            callback: fn context ->
              # Process.sleep(4000)
              IO.inspect(context)
              # IO.puts("After")
              {:ok, "After"}
            end
          },
          :cancel => %StateMachine.Transitions{
            target: "created canceled",
            before: nil,
            callback: nil
          }
        },
        :customer_confirmed => %{
          :invoice_created => %StateMachine.Transitions{
            target: "awaiting_payment",
            before: nil,
            callback: nil
          },
          :cancel => %StateMachine.Transitions{
            target: "customer_confirmed canceled",
            before: nil,
            callback: nil
          }
        }
      },
      modifiable_states: MapSet.new(["created"])
    })

  # IO.inspect(
  #   StateMachine.can_transition?(init_machine, "created.confirmed_by_customer"),
  #   structs: true
  # )

  # IO.inspect(
  #   StateMachine.modifiable?(init_machine),
  #   structs: true
  # )

  # IO.inspect(StateMachine.get_states(init_machine))

  # IO.inspect(

  # IO.inspect(
  #   StateMachine.modifiable?(init_machine, StateMachine.get_states(init_machine)),
  #   structs: true
  # )
  IO.inspect(
    StateMachine.get_states(init_machine),
    structs: true
  )

  StateMachine.transition(init_machine, "created.confirmed_by_customer")

  IO.inspect(
    StateMachine.get_states(init_machine),
    structs: true
  )

  # IO.inspect(
  #   StateMachine.get_states(init_machine),
  #   structs: true
  # )

  # IO.inspect(
  #   StateMachine.modifiable?(init_machine, StateMachine.get_states(init_machine)),
  #   structs: true
  # )

  # IO.inspect(StateMachine.get_states(init_machine))
end
