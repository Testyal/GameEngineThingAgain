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

typealias Message = (World) -> World

public struct World {
    
    let registry: [Entity]
    
    public init(_ registry: [Entity]) {
        self.registry = registry
    }
    
    func spawn(entity e: Entity) -> World {
        (self.registry + [e])
            .sorted { $0.hash < $1.hash }
            |> { World($0) }
    }
    
    func search(_ name: String) -> Entity? {
        registry.first { $0.hash == name.hashValue }
    }
    
    func kill(_ name: String) -> World {
        self.registry.compactMap { $0.name == name ? nil : $0 } |> { World($0) }
    }
    
    func map<T>(_ function: (T) -> (Entity, message: Message?)) -> (World, messages: [Message]) {
        var newRegistry: [Entity] = []
        var messages: [(World) -> World] = []
        
        for entity in self.registry {
            if let obj = entity as? T {
                let (newEntity, message) = function(obj)
                newRegistry.append(newEntity)
                if let msg = message { messages.append(msg) }
            } else {
                newRegistry.append(entity)
            }
        }
        
        return (World(newRegistry), messages: messages)
    }
    
    func retain<T>() -> [T] {
        return self.registry.compactMap { $0 as? T }
    }
    
}


protocol LogicSystem {
    func update(dt deltaTime: Double, input: [[Input]], world: World) -> (renderables: [Renderable], playables: [Playable], world: World)
}

class DefaultLogicSystem {

    let inputParser = InputParser()
        
    func update(dt deltaTime: Double, input: [[Input]], world: World) -> (renderables: [Renderable], playables: [Playable], world: World) {
        var worlde: World = world
                
        let (dx, newFace) = inputParser.parse(input)
        let face = newFace ?? "😼"
        
        worlde = worlde
            .map { (agent: Agent) in
                agent.update(dx: dx, face: face)
            }
            |> { (agentWorldE, agentMessages) in
                agentMessages.reduce(agentWorldE) { world, message in message(world) }
            }
    
        worlde = worlde
            .map { (patient: Patient) in
                patient.update()
            }
            |> { (patientWorldE, patientMessages) in
                patientMessages.reduce(patientWorldE) { world, message in message(world) }
            }

        let renderables = worlde.retain()
            .map { (providesRO: ProvidesTextRenderObject) in providesRO.renderObject }
        
        let rs: [Renderable] = [BackgroundRenderObject(".")]
            + renderables
            + [TextLineRenderObject("\(input.description): dx = \(dx)")]
        
        return (renderables: rs, playables: [], world: worlde)
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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
