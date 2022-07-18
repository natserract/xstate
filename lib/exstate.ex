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

  # order_statuses = [
  #   :created,
  #   :customer_confirmed,
  #   :awaiting_payment,
  #   :paid,
  #   :active,
  #   :fulfilled,
  #   :canceled
  # ]

  # order_events = [
  #   :confirmed_by_customer,
  #   :invoice_created,
  #   :payment_confirmed,
  #   :cancel
  # ]

  init_machine =
    StateMachine.new(%StateMachine.Machine{
      initial_state: "created",
      mapping: %{
        # TODO: Documenting layout of mapping
        :created => %{
          :confirmed_by_customer => %StateMachine.Transitions{
            target: "customer_confirmed",
            before: fn
              v ->
                try do
                  # exit(:crash)
                  # Process.exit(v.pid, :kill)
                  # IO.inspect(v.pid)
                  # {:ok, ""}

                  # :error
                  # :error
                  throw(:error)
                  # TryClauseError.exception("ERror")
                  # {:ok}
                catch
                  _, reason -> {:error, reason}
                end

                # exit(:normal)

                # Process.sleep(1000)
                # IO.inspect(v.pid)
            end,
            callback: fn v ->
              Process.sleep(2000)
              IO.puts("After #{v}")
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
