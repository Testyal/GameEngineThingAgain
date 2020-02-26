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

public class World {
    
    let registry: [UUID: Entity]
    
    public init(_ registry: [UUID: Entity]) {
        self.registry = registry
    }
    
    public func spawn(entity e: Entity) -> World {
        //print(e.uuid)
        return self.registry.merging([e.uuid: e]) { (e1, e2) in e1 } |> { World($0) }
    }
    
    func search(_ uuid: UUID) -> Entity? {
        registry[uuid]
    }
    
    func kill(_ uuid: UUID) -> World {
        var reg = registry
        reg.removeValue(forKey: uuid)
        
        return World(reg)
    }
    
    func kill(_ entity: Entity) -> World {
        return kill(entity.uuid)
    }
    
    func map<T>(_ function: (T) -> (Entity, message: Message?)) -> (World, messages: [Message]) {
        var newRegistry: [UUID: Entity] = [:]
        var messages: [Message] = []
        
        for entity in self.registry.values {
            if let obj = entity as? T {
                let (newEntity, message) = function(obj)
                newRegistry.merge([newEntity.uuid: newEntity]) { (e1, e2) in e1 }
                if let msg = message { messages.append(msg) }
            } else {
                newRegistry.merge([entity.uuid: entity]) { (e1, e2) in e1 }
            }
        }
        
        return (World(newRegistry), messages: messages)
    }
    
    func retain<T>() -> [T] {
        return registry.compactMap { (key, value) in value as? T }
    }
    
}


protocol LogicSystem {
    func update(dt deltaTime: Double, input: [[Input]], world: World) -> (renderables: [Renderable], playables: [Playable], world: World)
}

class DefaultLogicSystem: LogicSystem {

    let inputParser = InputParser()
        
    func update(dt deltaTime: Double, input: [[Input]], world: World) -> (renderables: [Renderable], playables: [Playable], world: World) {
        let (dx, face) = inputParser.parse(input)
        
        let updatedWorld: World = world.map { (agent: Agent) in agent.update(dx: dx, face: face)}
            |> { (agentWorld, agentMessages) in agentMessages.reduce(agentWorld) { world, message in message(world) } }
            |> { (world: World) in world.map { (patient: Patient) in patient.update() } }
            |> { (patientWorld, patientMessages) in patientMessages.reduce(patientWorld) { world, message in message(world) } }

        let renderables: [Renderable] = updatedWorld.retain().map { (providesRO: ProvidesTextRenderObject) in providesRO.renderObject }
            |> { (renderObjects: [Renderable]) in [BackgroundRenderObject(".")] + renderObjects }
        
        return (renderables: renderables, playables: [], world: updatedWorld)
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
