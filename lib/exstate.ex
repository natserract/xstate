defmodule Exstate do
  @moduledoc """
  Documentation for `Exstate`.
  """
  alias Exstate.StateMachine
  require Logger

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
                Process.sleep(2000)
                IO.inspect(context)
                IO.puts("Before")
                {:ok, "Before"}
              catch
                _, reason -> {:error, reason}
              end
            end,
            callback: fn context ->
              Process.sleep(4000)
              IO.inspect(context)
              IO.puts("After")
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
  #   StateMachine.can_transition(init_machine, "created.confirmed_by_customer"),
  #   structs: true
  # )
  # IO.inspect(
  #   StateMachine.modifiable(init_machine, :created),
  #   structs: true
  # )
  # IO.inspect(StateMachine.get_states(init_machine))

  IO.inspect(
    StateMachine.transition(init_machine, "created.confirmed_by_customer"),
    structs: true
  )

  # IO.inspect(StateMachine.get_states(init_machine))
end
