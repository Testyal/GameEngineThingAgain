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
    
    public init(_ x: Int) {
        self.actorPosition = x
    }
    
}


protocol LogicSystem {
    func update(dt deltaTime: Double, input: Input?, world frameData: World) -> (renderables: [Renderable], playables: [Playable], world: World)
}

class DefaultLogicSystem: LogicSystem {
    
    func update(dt deltaTime: Double, input: Input?, world: World) -> (renderables: [Renderable], playables: [Playable], world: World) {
        let dx: Int;
        
        switch input {
        case .some(.KEY_RIGHT): dx = +1
        case .some(.KEY_LEFT): dx = -1
        default: dx = 0
        }
        
        func clamp(_ x: Int, min: Int, max: Int) -> Int {
            if x < min {
                return min
            } else if x > max {
                return max
            }
            
            return x
        }
        
        let newActorPostion = clamp(world.actorPosition + dx, min: 0, max: 63)
        let newWorld = World(newActorPostion)
        
        return (renderables: [CharacterRenderObject("o", at: newActorPostion)], playables: [], world: newWorld)
    }
    
}

// TIME -- Functionally useless ///////////////////////////////////////////////////////////////////////////////////////////////////////
/*
typealias FrameTime = Double

protocol TimeSystem {
    func doWait(for time: FrameTime, callback: @escaping (FrameTime) -> Void)
}

class DefaultTimeSystem: TimeSystem {
    
    func doWait(for time: FrameTime, callback: @escaping (FrameTime) -> Void) {
        // DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 1_000_000_000)) {
        //    callback(time)
        // }
        usleep(1_000)
        callback(time)
    }
    
}
*/
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
            timer.schedule(deadline: .now(), repeating: .milliseconds(10), leeway: .milliseconds(1))

            //timer.suspend()
        }
        
        deinit {
            print("gameloop deinited")
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
        inputSystem = RandomInputSystem()
        logicSystem = DefaultLogicSystem()
        renderSystem = ConsoleRenderSystem()
        audioSystem = DefaultAudioSystem()
        gameLoop = nil
    }
    
    deinit {
        print("engine deinited")
    }
    
    func loopInternal(d: Double, w: World) -> World {
        let input = inputSystem.askInput()
        
        let outputs = logicSystem.update(dt: d, input: input, world: w)
        let renderables = outputs.renderables
        let sounds = outputs.playables
        let world = outputs.world
        
        renderSystem.doRender(objects: renderables)
        audioSystem.doPlaySounds(sounds: sounds)
    
        return world
    }
    
    public func doStartGame(initialWorld w: World) {
        gameLoop = GameLoop.doScheduleLoop(initialWorld: w, loop: loopInternal)
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

