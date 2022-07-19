defmodule Exstate do
  @moduledoc ~S"""
  This is the main `Exstate` module.

  ## Concept
   An abstract state machine is a software component that defines a finite set of states:

  - One state is defined as the initial state. When a machine starts to execute, it automatically enters this state.
  - Each state can define actions that occur when a machine enters or exits that state. Actions will typically have side effects.
  - Each state can define events that trigger a transition.
  - A transition defines how a machine would react to the event, by exiting one state and entering another state.
  - A transition can define actions that occur when the transition happens. Actions will typically have side effects.

  When “running” a state machine, this abstract state machine is executed.  The first thing that happens is that the state machine enters the “initial state”.  Then, events are passed to the machine as soon as they happen.  When an event happens:

  - The event is checked against the current state’s transitions.
  - If a transition matches the event, that transition “happens”.
  - By virtue of a transition “happening”, states are exited, and entered and the relevant actions are performed
  - The machine immediately is in the new state, ready to process the next event.

  Top-level `use`:
      use Exstate.StateMachine
  """

  use Exstate.StateMachine
end
