defmodule ExstateTest do
  use ExUnit.Case

  import Exstate
  alias Exstate.StateMachine

  test "Check existing event and event key accessor return properly" do
    state =
      %StateMachine.Machine{
        initial_state: "created",
        mapping: %{
          :created => %{
            :confirmed_by_customer => %StateMachine.Transitions{
              target: "customer_confirmed",
              before: nil,
              callback: nil
            }
          },
          :customer_confirmed => %{
            :invoice_created => %StateMachine.Transitions{
              target: "awaiting_payment",
              before: nil,
              callback: nil
            }
          }
        },
        modifiable_states: MapSet.new(["created"])
      }
      |> StateMachine.new()

    # Using atom
    assert true == StateMachine.can_transition?(state, :created)

    # Using string (if nested must use string)
    assert true == StateMachine.can_transition?(state, "created.confirmed_by_customer")

    # Incorrect key accessor
    assert false == StateMachine.can_transition?(state, "created.cancel")

    # Nested key
    assert true == StateMachine.can_transition?(state, "customer_confirmed.invoice_created")
  end

  test "Check if this state is modifiable" do
    state =
      %StateMachine.Machine{
        initial_state: "created",
        mapping: %{
          :created => %{
            :confirmed_by_customer => %StateMachine.Transitions{
              target: "customer_confirmed",
              before: nil,
              callback: nil
            }
          },
          :customer_confirmed => %{
            :invoice_created => %StateMachine.Transitions{
              target: "awaiting_payment",
              before: nil,
              callback: nil
            }
          }
        },
        modifiable_states: MapSet.new(["created"])
      }
      |> StateMachine.new()

    assert true == StateMachine.modifiable?(state, :created)

    # not modifiable state
    assert false == StateMachine.modifiable?(state, :customer_confirmed)
  end

  test "Check before or callback function invoked" do
    func = fn msg, inside ->
      IO.puts("#{msg} in #{inside}")
      {:ok, msg}
    end

    state =
      %StateMachine.Machine{
        initial_state: "created",
        mapping: %{
          :created => %{
            :confirmed_by_customer => %StateMachine.Transitions{
              target: "customer_confirmed",
              before: fn _ ->
                func.(:before_called, "created")
              end,
              callback: fn _ ->
                func.(:after_called, "created")
              end
            }
          },
          :customer_confirmed => %{
            :invoice_created => %StateMachine.Transitions{
              target: "awaiting_payment",
              before: fn _ ->
                func.(:before_called, "customer_confirmed")
              end,
              callback: fn _ ->
                func.(:after_called, "customer_confirmed")
              end
            }
          }
        },
        modifiable_states: MapSet.new(["created"])
      }
      |> StateMachine.new()

    # with side effect
    assert {:ok, :done} == StateMachine.transition(state, "created.confirmed_by_customer")
  end

  test "Check after transition will blocked if before transition error" do
    func = fn inside ->
      IO.puts("Should be called #{inside}")
      {:ok, "Should be called #{inside}"}
    end

    state =
      %StateMachine.Machine{
        initial_state: "created",
        mapping: %{
          :created => %{
            :confirmed_by_customer => %StateMachine.Transitions{
              target: "customer_confirmed",
              before: fn _ ->
                try do
                  throw(:error_created)
                catch
                  _, reason -> {:error, reason}
                end
              end,
              callback: fn _ ->
                func.("created")
              end
            }
          },
          :customer_confirmed => %{
            :invoice_created => %StateMachine.Transitions{
              target: "awaiting_payment",
              before: fn _ ->
                {:ok, "customer_confirmed"}
              end,
              callback: fn _ ->
                func.("customer_confirmed")
              end
            }
          }
        },
        modifiable_states: MapSet.new(["created"])
      }
      |> StateMachine.new()

    # With side effect, return error
    assert {:error, :bad, :error_created} ==
             StateMachine.transition(state, "created.confirmed_by_customer")

    # With side effect, return ok
    assert {:ok, :done} ==
             StateMachine.transition(state, "customer_confirmed.invoice_created")
  end

  # TODO: fix get _States
  test "Check resolved state" do
    state =
      %StateMachine.Machine{
        initial_state: "created",
        mapping: %{
          :created => %StateMachine.Transitions{
            target: "customer_confirmed",
            before: nil,
            callback: nil
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
    # assert "created" == StateMachine.get_states(state)
    # IO.puts(StateMachine.get_states(state))

    # Invoke transition
    # IO.inspect(StateMachine.transition(state, "created"))

    # state after transition
    # IO.puts(StateMachine.get_states(state))
    # assert "created" == StateMachine.get_states(state)
  end
end
