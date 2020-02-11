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
        let newActorFace: String = (faceKeys.last |> { actorFaces[$0]! }) ?? world.actorFace
        
        let newActorPostion = clamp(world.actorPosition + dx, min: 0, max: 63)
        let newWorld = World(actorPosition: newActorPostion, actorFace: newActorFace, frame: world.frame + 1)
        
        let rs: [Renderable] = [BackgroundRenderObject("."),
                                TextRenderObject(newActorFace, at: newActorPostion),
                                TextLineRenderObject("\(input.description): dx = \(dx)"),
                                TextLineRenderObject("Frame: \(world.frame + 1)")]
        
        return (renderables: rs, playables: [], world: newWorld)
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
