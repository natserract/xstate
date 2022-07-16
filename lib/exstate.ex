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
  order_statuses = [
    :created,
    :customer_confirmed,
    :awaiting_payment,
    :paid,
    :active,
    :fulfilled,
    :canceled
  ]

  order_events = [
    :confirmed_by_customer,
    :invoice_created,
    :payment_confirmed,
    :cancel
  ]

  init_machine =
    StateMachine.new(%StateMachine.Machine{
      initial_state: "created",
      mapping: %{
        :created => %{
          :confirmed_by_customer => %StateMachine.Transitions{
            target: "customer_confirmed",
            predicate: nil,
            before: nil,
            callback: nil
          },
          :cancel => %StateMachine.Transitions{
            target: "canceled",
            predicate: nil,
            before: nil,
            callback: nil
          }
        },
        :customer_confirmed => %{
          :invoice_created => %StateMachine.Transitions{
            target: "awaiting_payment",
            predicate: nil,
            before: nil,
            callback: nil
          },
          :cancel => %StateMachine.Transitions{
            target: "canceled",
            predicate: nil,
            before: nil,
            callback: nil
          }
        }
      },
      modifiable_states: MapSet.new(["created"])
    })

  IO.inspect(
    StateMachine.can_transition(init_machine, :created),
    structs: true
  )

  IO.inspect(
    StateMachine.modifiable(init_machine, :created),
    structs: true
  )
end
