//
//  Entity.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 19/02/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation
import Pipes

// PROTOCOLS //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public protocol Entity {
    var name: String { get }
    var uuid: UUID { get }
}


protocol Patient: Entity {
    func update() -> (Self, message: Message?)
}

protocol Agent: Entity {
    func update(dx: Int, face: Character?) -> (Self, message: Message?)
}


protocol IndependentPatient: Patient {
    func update() -> Self
}

extension IndependentPatient {
    func update() -> (Self, message: Message?) {
        return (update(), message: nil)
    }
}


protocol ProvidesTextRenderObject: Entity {
    var renderObject: TextRenderObject { get }
}

protocol CharacterSprite: ProvidesTextRenderObject {
    var sprite: Character { get }
    var position: Int { get }
}

extension CharacterSprite {
    var renderObject: TextRenderObject { TextRenderObject(String(sprite), at: position) }
}

protocol AnimatedSprite: CharacterSprite, Patient {
    var sprites: [Character] { get }
    var frame: Int { get }
    func nextFrame() -> Self
}

extension AnimatedSprite {
    func update() -> (Self, message: Message?) {
        if frame == sprites.count - 1 { return (self, { $0.kill(self) }) }
        return (self.nextFrame(), nil)
    }
    
    var sprite: Character { sprites[frame] }
}


protocol Movable: Entity {
    var position: Int { get }
    func position(_ x: Int) -> Self
}

extension Movable {
    func moved(_ dx: Int) -> Self {
        return position(position + dx)
    }
}


public enum Facing {
    case left
    case right
    
    func flipped() -> Facing {
        return self == .left ? .right : .left
    }
    
    var numeric: Int { self == .right ? +1 : -1 }
}

extension Int {
    func asFacing(biasedToward bias: Facing = .right) -> Facing {
        if self > 0 { return .right }
        if self < 0 { return .left }
        return bias
    }
}

protocol Faced: Entity {
    var facing: Facing { get }
}

extension Faced where Self: Movable {
    func movedForward(_ dx: Int) -> Self {
        return moved(facing == .right ? +dx : -dx)
    }
    
    func movedBackward(_ dx: Int) -> Self {
        return moved(facing == .right ? -dx : +dx)
    }
}


// ENTITIES ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// TODO: Automatically deriving a builder pattern such as in https://github.com/colin-kiegel/rust-derive-builder would be wonderful
public struct Actor: Entity, Movable, CharacterSprite, Agent {
        
    public let sprite: Character
    public let position: Int
    
    public let name: String
    public let uuid: UUID
    
    public static func new(sprite: Character, position: Int) -> Actor {
        return Actor(sprite: sprite,
                     position: position,
                     name: "Untitled Actor",
                     uuid: UUID())
    }
    
    func sprite(_ sprite: Character) -> Self {
        return Actor(sprite: sprite,
                     position: self.position,
                     name: self.name,
                     uuid: self.uuid)
    }
    
    func position(_ position: Int) -> Self {
        return Actor(sprite: self.sprite,
                     position: position,
                     name: self.name,
                     uuid: self.uuid)
    }
        
    func update(dx: Int, face: Character?) -> (Self, message: Message?) {
        let actor = self
            .moved(dx)
            |> { $0.position(clamp($0.position, min: 0, max: 63)) }
            |> { $0.sprite(face ?? $0.sprite) }
        
        if face == "😳" {
            let spawnMessage = { (world: World) -> World in
                world.spawn(entity: Bullet(position: actor.position,
                                           facing: dx.asFacing(),
                                           name: "\(self.name)'s bullet",
                                           uuid: UUID()))
            }
            
            return (actor, spawnMessage)
        }
        
        return (actor, nil)
    }
    
}


public struct Enemy: Entity, Faced, Movable, CharacterSprite, IndependentPatient {
    
    let position: Int
    let facing: Facing
    
    public let name: String
    public let uuid: UUID
    
    let sprite: Character = "😈"
    
    public static func new(name: String, position: Int, facing: Facing) -> Enemy {
        return Enemy(position: position,
                     facing: facing,
                     name: name,
                     uuid: UUID())
    }
    
    func position(_ position: Int) -> Self {
        return Enemy(position: position,
                     facing: self.facing,
                     name: self.name,
                     uuid: self.uuid)
    }
    
    func turned() -> Self {
        return Enemy(position: self.position,
                     facing: self.facing.flipped(),
                     name: self.name,
                     uuid: self.uuid)
    }
    
    func update() -> Self {
        return self.movedForward(1)
            |> { (enemy: Enemy) -> Self in
                if enemy.position == 63 || enemy.position == 0 { return enemy.turned() }
                return enemy
            }
    }
    
}


public struct Bullet: Entity, Faced, Movable, CharacterSprite, Agent {
    
    let position: Int
    let facing: Facing
    
    public let name: String
    public let uuid: UUID
    
    var sprite: Character { facing == .right ? "👉" : "👈" }
    
    func position(_ position: Int) -> Self {
        return Bullet(position: position,
                      facing: self.facing,
                      name: self.name,
                      uuid: self.uuid)
    }
    
    func turned() -> Bullet {
        return Bullet(position: self.position,
                      facing: self.facing.flipped(),
                      name: self.name,
                      uuid: self.uuid)
    }
    
    func update() -> (Self, message: Message?) {
        return self
            .movedForward(1)
            |> { (bullet: Bullet) -> (Self, Message?) in
                if bullet.position == -1 || bullet.position == 64 {
                    return (bullet, { $0.kill(bullet) })
                }
                
                return (bullet, nil)
            }
    }
    
    func update(dx: Int, face: Character?) -> (Self, message: Message?) {
        let (bullet, message): (Self, Message?)
        switch face {
            /*
        case "😡": (entity, message) = (self, { (world: World) -> World in
            if Int.random(in: 0...4) == 0 { return world.kill(self) }
            return world
        })
              
        case "😳": (entity, message) = (self, { (world: World) -> World in
            let player: Actor = world.retain()[0]
            let dx = self.position - player.position
            
            if dx.signum() == self.facing.numeric {
                return world
                    .kill(self)
                    |> { $0.spawn(entity: self.turned().movedForward()) }
            }
            
            return world
        })*/
            
        default: (bullet, message) = (self.movedForward(1), nil)
        }
                        
        let spawnSmokeTrail = { (world: World) -> World in
            world.spawn(entity: SmokeTrail(frame: -1,
                                           position: self.position,
                                           name: "\(self.name)'s SmokeTrail",
                                           uuid: UUID()))
        }
        
        if bullet.position == -1 || bullet.position == 64 {
            return (bullet, message >>> { $0.kill(bullet) } >>> spawnSmokeTrail)
        }
        
        return (bullet, message >>> spawnSmokeTrail)
    }
    
}


struct SmokeTrail: Entity, AnimatedSprite {
    
    let sprites: [Character] = ["~", "~"]
    let frame: Int
    let position: Int
    
    public let name: String
    public let uuid: UUID
    
    func nextFrame() -> Self {
        return SmokeTrail(frame: self.frame + 1,
                          position: self.position,
                          name: self.name,
                          uuid: self.uuid)
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
