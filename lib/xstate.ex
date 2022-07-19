defmodule Xstate do
  @moduledoc ~S"""
  This is the main `Xstate` module.

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

  More resources:
  - [Finite-state machine](https://en.wikipedia.org/wiki/Finite-state_machine) article on Wikipedia
  - [Understanding State Machines](https://www.freecodecamp.org/news/state-machines-basics-of-computer-science-d42855debc66/) by Mark Shead
  - [A-Level Comp Sci: Finite State Machine](https://www.youtube.com/watch?v=4rNYAvsSkwk)

  Top-level `use`:
      use Xstate.StateMachine
  """

  use Xstate.StateMachine
end
