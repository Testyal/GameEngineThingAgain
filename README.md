# GameEngineThingAgain

This skeleton of a game engine was started after a small detour into learning Haskell as a way to incorporate techniques from there (immutable state, functional programming, dataflow) into what the author has been wanting to do since summer 2019.

All files for this project are currently all over the place as the Xcode project transitioned from something completely different, and the author committed everything to Git out of a fear of Xcode's fragility when (re)moving files. They can be found in the directory `/GameEngine/src` (excluding `CountdownTimer.swift` and `Battle.swift`), and in the file `/SampleGame/main.swift`.

# Architecture

The engine is currently composed of a small number of independent systems, and a larger, vague black box "LogicSystem". Every frame, the game loop takes input from the InputSystem, the time since the last frame from what should be the TimeSystem (but is instead a hardcoded value), and passes these two objects, plus a "World" object generated from the last frame, to the LogicSystem. This system then constructs a new World object, a number of Renderable objects, and a number of Audio objects from its inputs. The Engine passes these objects respectively to the LogicSystem in the next frame, the RenderSystem, and the AudioSystem. It's pretty much just a state machine with a more violent tape. 

![Skeleton architecture](/GameEngine/docs/architecturediagram.pdf)

*(Figure: diagram of skeleton architecture)*

The LogicSystem must be pure (in the sense of a [pure function](https://en.wikipedia.org/wiki/Pure_function). All other systems mentioned are supposed to be the endpoints of the architecture, and are allowed to be a little bit naughty. It's worth noting that (almost?) every function which performs an action liking printing to the screen or (in the future) playing audio is prefixed with "do", such as in `RenderSystem.doRender`. No method is allowed to mutate variables outside of its scope.

## Performance

By its functional nature, any method intended to update an object should return a new object (rather than mutating it in place). This introduces a performance issue, one which is explicitly noted in the [Swift docs](https://github.com/apple/swift/blob/master/docs/OptimizationTips.rst#advice-use-inplace-mutation-instead-of-object-reassignment). Namely, the following code will produce a deep copy of `a`, despite `a` not being used again.
```
let a: [Int] = [1,2,3]
let b = a + [4]
print(b)
```
The faster way to do this would be to set `a` as a `var` and modify it in place.

Since this is more of a project in architecting something which looks kind of nice (as opposed to being performant), keeping with the original plan of reassigning things will be fine for now. After a good-looking architecture is available, rewriting things with performance in mind will be a priority. There could be a potential rewrite in another language, especially considering the author only chose Swift because the syntax makes him happy 😊
