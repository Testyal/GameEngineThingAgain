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

/*
Potentially uniquely for this program, I'm applying with a degree in mathematics. Since I graduated, it's been clear to me that software development is the career path I want to follow. Developing video games is an even greater goal, since the game industry is one I've been following for years. The Ubisoft Graduate Program immediately struck me as a way to jumpstart my career in this industry with a company that has established a wide range of franchises, products, and ideas in its almost 34-year history.

My goal has led me over the past few months to learn a broad range of skills in programming to fill in many of the gaps that my degree missed. In particular, I've gone from learning about UE4, to Unity, to graphics programming, functional and object-oriented programming, and more. Along the way, I've picked up as much as I can about data structures, algorithms, heap/stack, and other important aspects of computer science. Importantly though, the maths degree I have enables me to think abstractly about problems I encounter, and to quickly learn new ideas and methods to tackle these problems.

It would be incredible to have the chance to show Ubisoft the unique skills I can bring, and I look forward to hearing back soon!

// role of gameplay programmer
A skilled gameplay programmer is able to take a gameplay idea, and using the tools available to them, stretch it as far as it will go and reward the player for experimenting with the idea and using it in imaginative ways. For example, Super Mario Bros has the core idea of running and jumping.
 
 The tools available back when game development was still young would have been C or assembly, compared to high-level languages and visual programming languages (such as UE4's blueprints) that are available now. The ability of early developers to make fun gameplay mechanics with such limited tools is testament to their skill.
 
// key for game to be successful
A successful game is one that constantly has the player saying "I want to play another level/match" or "I wonder what happens next".

// game inspiration
When I was young, my dad had a SNES and an N64 I was allowed to play on. Yoshi's Island was the game I probably spent most of my time on, replaying it over and over because the core gameplay mechanics of running, jumping, and throwing eggs was so fluid, the levels were expansive and rewarded the player for going out of their way to find hidden red coins and flowers, and the final boss music is remarkably good. A few years later, when I was about 10 or 11, I discovered GameMaker and spent almost all my time on it making platformers, inspired by my time with Yoshi's Island.
*/
