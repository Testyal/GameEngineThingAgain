//
//  Engine.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 22/01/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation
import Dispatch

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

