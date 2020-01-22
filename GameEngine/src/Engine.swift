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

// INPUT //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

enum Input {
    case KEY_A
}


protocol InputSystem {
    func askInput() -> Input
}

class DefaultInputSystem: InputSystem {
    
    func askInput() -> Input {
        return .KEY_A
    }
    
}

// RENDER /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

protocol Renderable {
    func show() -> String
}

struct TextRenderObject: Renderable {
    
    let text: String
    
    func show() -> String {
        return text
    }
    
}


protocol RenderSystem {
    func doRender(objects renderableObjects: [Renderable])
}

class DefaultRenderSystem: RenderSystem {
    
    func doRender(objects ros: [Renderable]) {
        ros.forEach { ro in
            print(ro.show())
        }
    }
    
}

// AUDIO //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typealias WhateverARealSoundObjectIs = Int

protocol Playable {
    func play() -> WhateverARealSoundObjectIs
}

struct SoundObject: Playable {
    
    func play() -> WhateverARealSoundObjectIs {
        return 0
    }
    
}


protocol AudioSystem {
    func doPlaySounds(sounds playableObjects: [Playable])
}

class DefaultAudioSystem: AudioSystem {
    
    func doPlaySounds(sounds pos: [Playable]) {
        pos.forEach { po in
            print(po.play())
        }
    }
    
}

// TIME ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

// LOGIC //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class World {
    
    let x: Int
    
    init(_ x: Int) {
        self.x = x
    }
    
    deinit {
        print("world deinited")
    }
    
}

protocol LogicSystem {
    func update(delta deltaTime: FrameTime, input: Input, world frameData: World?) -> (renderables: [Renderable], playables: [Playable], world: World?)
}

class DefaultLogicSystem: LogicSystem {
    
    func update(delta deltaTime: FrameTime, input: Input, world: World?) -> (renderables: [Renderable], playables: [Playable], world: World?) {
        let myRenderableObject = TextRenderObject(text: "hello world, \(deltaTime) seconds have passed" + (world != nil ? ", the world's x value is \(world!.x)" : "."))
        let mySoundObject = SoundObject()
        
        let newWorld = world != nil ? World(world!.x + 1) : nil
        
        return (renderables: [myRenderableObject], playables: [mySoundObject], world: newWorld)
    }
    
}

// ENGINE /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class Engine {
    
    let inputSystem: InputSystem
    let logicSystem: LogicSystem
    let renderSystem: RenderSystem
    let audioSystem: AudioSystem
    let timeSystem: TimeSystem
    
    public init() {
        inputSystem = DefaultInputSystem()
        logicSystem = DefaultLogicSystem()
        renderSystem = DefaultRenderSystem()
        audioSystem = DefaultAudioSystem()
        timeSystem = DefaultTimeSystem()
    }
    
    public func doSetupGame() {
        doGameLoop(delta: 0.0, previousFrame: World(0))
    }
    
    // TODO: The stack really doesn't enjoy this
    func doGameLoop(delta deltaTime: FrameTime, previousFrame data: World?) {
        let input = inputSystem.askInput()
        
        let outputs = logicSystem.update(delta: deltaTime, input: input, world: data)
        let renderables = outputs.renderables
        let sounds = outputs.playables
        weak var world = outputs.world
        
        renderSystem.doRender(objects: renderables)
        audioSystem.doPlaySounds(sounds: sounds)
        
        usleep(1_000)
        doGameLoop(delta: 1.0, previousFrame: world)
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

