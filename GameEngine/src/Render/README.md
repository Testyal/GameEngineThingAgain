# RenderSystem

In a nutshell, the RenderSystem acts by taking a number of Renderable objects, transforms them into code for a Renderer object to handle, has the Renderer handle this code, and prints the result.

In more detail, we start with the Renderer. In the file `GameEngine/src/Render.swift`, the current Renderer available is the ConsoleRenderer, which contains a number of methods with the type `(T1, ..., Tn, onto: [Character]) -> [Character]` for some types T1, ..., Tn. The `onto: [Character]` parameter in these methods represents a display at a given time during rendering. For example, this may be an array of 64 empty characters, or an array containing the sequence [".", "-"] repeated 32 times. Each of these methods draws something new on the display given the other parameters, and returns this display (as a necessary consequence of using immutable state). The prevailing example of these methods is `write(text t: String, at x: Int, onto s: [Character]) -> [Character]`, which writes text onto the display at a given position. 
```swift
let r = ConsoleRenderer()

let display = [Character](repeating: "*", count: 10)  // ["*", "*", "*", "*", "*", "*", "*", "*", "*", "*"]
let outDisplay = r.write(text: "hello", at: 2, onto: display)   // ["*", "*", "h", "e", "l", "l", "o", "*", "*", "*"]
```

A RenderInstruction (probably better named ConsoleRenderInstruction) is a function of type `(ConsoleRenderer, [Character]) -> [Character]`. An array [RenderInstruction] of RenderInstructions is usually called render code. Renderable objects (i.e. those objects adhering to the Renderable protocol) must implement the method `render() -> [RenderInstruction]`, which provides code to tell the Renderer how it would like to be drawn, usually in the form of an array of closures like `{(r, s) in r.write(text: "hello", at: 2, onto: s)}`. Currently, all available Renderable objects only provide a single RenderInstruction, but the idea is for there to be as few RenderInstructions as possible (to increase reusability) and for the Renderable objects to write potentially complex code. For example, for a future Renderer capable of drawing a 2D console image (a bit like [Rogue](https://en.wikipedia.org/wiki/Rogue_(video_game))), a BoxRenderObject may have two properties p<sub>1</sub> = (x<sub>1</sub>, y<sub>1</sub>) and p<sub>2</sub> = (x<sub>2</sub>, y<sub>2</sub>) representing the positions of its top-left and bottom-right corners, and `render()` would produce the render instructions
```swift
{(r, s) in r.drawLine(from: (x1,y1), to: (x2,y1), angle: .horizontal, onto: s)}
{(r, s) in r.drawLine(from: (x2,y1), to: (x2,y2), angle: .vertical, onto: s)}
{(r, s) in r.drawLine(from: (x1,y2), to: (x2,y2), angle: .horizontal, onto: s)}
{(r, s) in r.drawLine(from: (x1,y2), to: (x1,y1), angle: .vertical, onto: s)}
```
Come to think of it, using an array of RenderInstructions to represent render code is a bit redundant when just writing
```swift
{(r, s) in 
r.drawLine(from: (x1,y1), to: (x2,y1), angle: .horizontal, onto: s)
r.drawLine(from: (x2,y1), to: (x2,y2), angle: .vertical, onto: s)
r.drawLine(from: (x1,y2), to: (x2,y2), angle: .horizontal, onto: s)
r.drawLine(from: (x1,y2), to: (x1,y1), angle: .vertical, onto: s)
}
```
is just as effective.

The RenderSystem is provided an array of Renderable objects in whichever order the LogicSystem decides, and draws the objects in the order they appear in the array. That is, for each Renderable object in the array starting from 0, it appends render code obtained from this object onto the end of output render code. This code is then executed in the order it appears, like some kind of weirdo bytecode.

Currently, the RenderSystem is capable of printing lines of characters, and it is planned to stay this way until all other systems have a basic implementation and the LogicSystem is less of a black box.
