//
//  Engine.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 22/01/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation
import Dispatch

//
// Beyond this point lies experiments in single-threaded game engine architecture with an emphasis on immutability, flow of data,
// and functional programming. Tread lightly.
//

// LOGIC //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class World {
    
    let actorPosition: Int
    let actorFace: String
    let frame: Int
    
    public init(actorPosition x: Int, actorFace face: String, frame fr: Int) {
        self.actorPosition = x
        self.actorFace = face
        self.frame = fr
    }
    
}


protocol LogicSystem {
    func update(dt deltaTime: Double, input: [[Input]], world frameData: World) -> (renderables: [Renderable], playables: [Playable], world: World)
}

class DefaultLogicSystem: LogicSystem {
    
    func deltaPostion(from input: Input) -> Int {
        switch input {
        case .KEY_LEFT: return -1
        case .KEY_RIGHT: return +1
        default: return 0
        }
    }
    
    func update(dt deltaTime: Double, input: [[Input]], world: World) -> (renderables: [Renderable], playables: [Playable], world: World) {
        let arrowKeys = input.flatMap { $0.filter { [Input.KEY_LEFT, Input.KEY_RIGHT].contains($0) } }
        let faceKeys = input.flatMap { $0.filter { [Input.KEY_R, Input.KEY_F, Input.KEY_T].contains($0) } }
        
        let dx = arrowKeys.reduce(0) { $0 + deltaPostion(from: $1) }
        
        func clamp(_ x: Int, min: Int, max: Int) -> Int {
            if x < min {
                return min
            } else if x > max {
                return max
            }
            
            return x
        }
        
        let actorFaces = [Input.KEY_T: "🤔", Input.KEY_R: "😡", Input.KEY_F: "😳"]
        let newActorFace: String
        if let f = faceKeys.last {
            newActorFace = actorFaces[f]!
        } else {
            newActorFace = world.actorFace
        }
        
        let newActorPostion = clamp(world.actorPosition + dx, min: 0, max: 63)
        let newWorld = World(actorPosition: newActorPostion, actorFace: newActorFace, frame: world.frame + 1)
        
        let rs: [Renderable] = [BackgroundRenderObject("."),
                                TextRenderObject(newActorFace, at: newActorPostion),
                                TextLineRenderObject("\(input.description): dx = \(dx)"),
                                TextLineRenderObject("Frame: \(world.frame + 1)")]
        
        return (renderables: rs, playables: [], world: newWorld)
    }
    
}

// ENGINE /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class Engine {
    
    class GameLoop {
        
        var world: World
        let timer: DispatchSourceTimer
        let doLoop: (Double, World) -> World
        
        init(initialWorld: World, loop: @escaping (Double, World) -> World) {
            world = initialWorld
            doLoop = loop
            
            timer = DispatchSource.makeTimerSource(queue: .global(qos: .default))
            timer.setEventHandler { [unowned self] in
                self.world = self.doLoop(0.5, self.world)
            }
            timer.schedule(deadline: .now(), repeating: .milliseconds(50), leeway: .milliseconds(1))
        }
        
        func doBeginLoop() {
            timer.resume()
        }
        
        static func doScheduleLoop(initialWorld: World, loop: @escaping (Double, World) -> World) -> GameLoop {
            let gameLoop = GameLoop(initialWorld: initialWorld, loop: loop)
            gameLoop.doBeginLoop()
            
            return gameLoop
        }
        
    }
    
    let inputSystem: InputSystem
    let logicSystem: LogicSystem
    let renderSystem: RenderSystem
    let audioSystem: AudioSystem
    var gameLoop: GameLoop?
    
    public init() {
        inputSystem = InputSystem()
        logicSystem = DefaultLogicSystem()
        renderSystem = ConsoleRenderSystem()
        audioSystem = DefaultAudioSystem()
        gameLoop = nil
    }
    
    func loopInternal(d: Double, w: World) -> World {
#if BENCH
        let start = DispatchTime.now()
#endif
        
        let inputs = inputSystem.requestInputBuffer()
        
#if BENCH
        let inputTime = DispatchTime.now()
        print("input retrieval finished in \((inputTime.uptimeNanoseconds - start.uptimeNanoseconds)/1000) μs")
#endif
        
        //print(inputs)
        let outputs = logicSystem.update(dt: d, input: inputs, world: w)
        let renderables = outputs.renderables
        let sounds = outputs.playables
        let world = outputs.world
        
#if BENCH
        let updateTime = DispatchTime.now()
        print("world update finished in \((updateTime.uptimeNanoseconds - inputTime.uptimeNanoseconds)/1000) μs")
#endif
        
        renderSystem.doRender(objects: renderables)
        audioSystem.doPlaySounds(sounds: sounds)
        
#if BENCH
        let end = DispatchTime.now()
        print("render and audio work finished in \((end.uptimeNanoseconds - updateTime.uptimeNanoseconds)/1000) μs" )
        print("loop finished in \((end.uptimeNanoseconds - start.uptimeNanoseconds)/1000) μs")
#endif
        
        return world
    }
    
    public func doStartGame(initialWorld w: World) {
        gameLoop = GameLoop.doScheduleLoop(initialWorld: w, loop: loopInternal)
        inputSystem.startInputLoop()
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

