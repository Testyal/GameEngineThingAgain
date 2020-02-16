//
//  Logic.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 11/02/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation
import Pipes

// LOGIC //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class World {
    
    let actor: Actor
    let frame: Int
    
    public init() {
        self.actor = Actor()
        self.frame = 0
    }
    
    public init(actor a: Actor, frame fr: Int) {
        self.actor = a
        self.frame = fr
    }
    
    func actor(_ a: Actor) -> World {
        return World(actor: a, frame: self.frame)
    }
    
    func nextFrame() -> World {
        return World(actor: self.actor, frame: self.frame + 1)
    }
    
}


protocol LogicSystem {
    func update(dt deltaTime: Double, input: [[Input]], world frameData: World) -> (renderables: [Renderable], playables: [Playable], world: World)
}

class DefaultLogicSystem: LogicSystem {
    
    let inputParser = InputParser()
    
    func update(dt deltaTime: Double, input: [[Input]], world: World) -> (renderables: [Renderable], playables: [Playable], world: World) {
        let (dx, newFace) = inputParser.parse(input)
        let face = newFace ?? world.actor.face
    
        let actor = world.actor
            .moved(dx)
            .face(face)
            |> { $0.position(clamp($0.position, min: 0, max: 63)) }
        
        let world = world
            .actor(actor)
            .nextFrame()
        
        let rs: [Renderable] = [BackgroundRenderObject("."),
                                actor.asRenderObject(),
                                TextLineRenderObject("\(input.description): dx = \(dx)"),
                                TextLineRenderObject("Frame: \(world.frame + 1)")]
        
        return (renderables: rs, playables: [], world: world)
    }
    
}


class InputParser {
    
    let actorFaces: [Input: Character] = [Input.KEY_T: "🤔", Input.KEY_R: "😡", Input.KEY_F: "😳"]
    
    func deltaPosition(from input: Input) -> Int {
        switch input {
        case .KEY_LEFT: return -1
        case .KEY_RIGHT: return +1
        default: return 0
        }
    }
    
    func parse(_ input: [[Input]]) -> (dx: Int, face: Character?) {
        let arrowKeys = input.flatMap { $0.filter { [Input.KEY_LEFT, Input.KEY_RIGHT].contains($0) } }
        let faceKeys = input.flatMap { $0.filter { [Input.KEY_R, Input.KEY_F, Input.KEY_T].contains($0) } }
        
        let dx = arrowKeys.reduce(0) { $0 + deltaPosition(from: $1) }
        let face = faceKeys.last |> { actorFaces[$0]! }
        
        return (dx: dx, face: face)
    }
    
}


// TODO: Automatically deriving a builder pattern such as in https://github.com/colin-kiegel/rust-derive-builder would be wonderful
public class Actor {
    
    let face: Character
    let position: Int
    
    init() {
        self.position = 0
        self.face = "😐"
    }
    
    init(position x: Int, face f: Character) {
        self.position = x
        self.face = f
    }
    
    func face(_ f: Character) -> Actor {
        return Actor(position: self.position, face: f)
    }
    
    func position(_ x: Int) -> Actor {
        return Actor(position: x, face: self.face)
    }
    
    func moved(_ dx: Int) -> Actor {
        return position(self.position + dx)
    }
    
    func asRenderObject() -> TextRenderObject {
        return TextRenderObject(String(self.face), at: self.position)
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

