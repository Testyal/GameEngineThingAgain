# Input System
The Input system provides the engine with raw input from devices such as the keyboard, mouse, or controller. Currently, the system only supports a limited number of keyboard keys.

## Philosophy
Continuing the philosophy of the render system, the input system is made to be as small as possible (but no smaller), and so it performs as few transformations to the raw input as possible. There will be a slight departure from the sketch of Feb 3, 2020. Instead of producing the `pressed/held/released` events within the system, the logic system will be provided with with a raw buffer indicating the keys held (among other input events like mouse movement and controller trigger position) at particular times. Given this buffer, the logic system can then map keys/buttons/mouse actions to `pressed/held/released` events, which can then also be mapped to independent axis/action commands (such as that in the new Unity input system, or UE4).

## Mechanism
Internal to the system lives an object implementing `InputProvider`, which has the method `askInput() -> [Input]`. When this method is called, the provider polls the relevant device for the current status of its keys, returning an `[Input]` object. Currently, an empty array is returned if no keys are pressed. The only `InputProvider` class available so far is the `RandomInputProvider` object, whose `askInput` method returns singleton arrays for each available key in `Input` at random.

More fundamental to the system is the `InputLoop` object, which calls `askInput()` at fixed intervals (input frame time) almost entirely independently of the engine, under the condition that it must be faster than the maximum possible engine frame time. An advantage of this approach is that we can accurately calculate the amount of time a key is held for, within the interval set by the input frame time. In particular, this provides a degree of predictability to the game (hold the up button for 1 s and the player moves 2 m, independent of whether the game is running at 240 fps or at 10 fps). Of course, this could probably also be done by going deeper and looking at interrupt-level logic, but that might need a really big brain. This loop adds the given input to a buffer object (of type `[[Input]]`). Necessarily, the loop is run on a `DispatchQueue` separate to the engine (although the `QoSClass` is `userInteractive`, granting the input loop higher execution priority to the engine).  The `InputLoop` implements the method `requestInput(_ handler: @escaping ([[Input]]) -> Void)`, which gets the current buffer, calls the `handler` on it, then clears the buffer. To ensure thread-safety, `requestInput` and the internal loop function use semaphores to ensure that `requestInput` cannot clear the buffer until the loop has written to it (and vice versa), thereby ensuring no input is consumed between frames. There is also the method `requestInput() -> [[Input]]` which returns the input buffer after the `InputLoop` has acted on it. This allows the engine loop to not have to pass a closure to retrieve the buffer, but causes the code to veer a bit more into imperative programming. This is the author's first foray into asynchronous programming (Grand Central Dispatch in particular), so it's probably a lot clumsier than it could be (but it was very satisfying when it worked!). 

#  Input System sketch (Feb 3, 2020)
## Goals
* The input system should produce the key events pressed/released/held for each raw controller input (e.g. pressed the 'A' key, pressed the 'Square' button, etc).

## Issues
1. A potential issue with a simple polling system is that if the engine frame time is particularly large - as though we're playing OoT on the N64 - there may be circumstances in which a button is pressed and released between input polls, leading to UX problems in which the user feels the input was consumed by the engine, but no response occurs. This issue isn't exactly a problem for the childlike nursery engine that exists so far, but it makes for a nice little exercise in how to fix this problem.
2. A more prominent issue arises with the kind of philosophy with the engine. Namely, that (almost) all state should be immutable. If we want a system which says "this key was pressed (i.e. it was not active at the previous frame)", or "this key was released (i.e. it was active at the previous frame but not at this frame)", then the system needs some kind of memory to keep track of which keys were down in the last frame. Currently, the only memory we have is the `world` object. The two basic solutions to this issue are 1. adding a, say, `previousFrameInput` property in `world`, or 2. adding a `previousFrameInput:` parameter to the loop method. Ignoring performance, both solutions have, in some way, a problem of data from unrelated systems seeping into places where they shouldn't. The `world` object is currently an inelegant solution to the initial problem of removing mutable state from the engine, existing only to dump game state objects until a more elegant solution is found. Putting unrelated data from the input system, or a possible future animation system, into `world` is deferring the solution until later. Adding a `previousFrameInput:` parameter to the loop method only has the relative benefit over solution 1. of removing the cost of deferencing the `world` object, but does not solve the major issue at hand.

## Potential solutions
1. The simplest implementation of an input system is to poll for current inputs whenever the engine calls `askInput()`. This conflicts with issues 1. and 2.
2. A big brain solution is to have the input system run on its own loop with its own framerate which should be at least as fast as the maximum engine framerate. In this loop, there is an input buffer of some length related to the engine frame time containing input events. the system asks the computer for the raw input, then it uses this plus the buffer passed over from the previous input loop to compute events and, add them to the buffer, and return the buffer ready for the next pass of the loop. An example buffer could look like the following (with `p(x)` meaning "key `x` was pressed", `h(x)` meaning "key `x` was held", and `r(x)` meaning "key `x` was released"):
```
INPUT  | .    .    .    p(A) h(A) h(A) h(A) r(A) .    p(S) h(S) h(S) h(S) h(S) h(S) h(S) r(S) .
       | .    .    .    .    .    .    .    .    .    .    .    p(D) h(D) r(D) .    .    .    .
```
This now presents an issue which the author is nowhere near big-brained enough to solve. Namely, suppose the engine is now asking for the input. How does it get the buffer, and how is the buffer cleared? More importantly, what should a loop look like? The current engine loop was stitched together like a maniac whose only goal was just "uhh make a loop because recursion is causing a stack overflow", and contains contains the only significant `var` in the code. Making a nice architectural change in this area in order to facilitate an input loop should therefore be a priority. 

