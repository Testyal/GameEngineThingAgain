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

public class Entity {
    
    let name: String
    let uuid: UUID
    
    init(name: String = "Untitled") {
        self.uuid = UUID()
        self.name = name
    }
    
}


protocol Patient: Entity {
    func update() -> (Entity, message: Message?)
}

protocol Agent: Entity {
    func update(dx: Int, face: Character?) -> (Entity, message: Message?)
}


protocol IndependentPatient: Patient {
    func update() -> Entity
}

extension IndependentPatient {
    func update() -> (Entity, message: Message?) {
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
    func nextFrame() -> AnimatedSprite
}

extension AnimatedSprite {
    func update() -> (Entity, message: Message?) {
        if frame == sprites.count - 1 { return (self, { $0.kill(self) }) }
        return (self.nextFrame(), nil)
    }
    
    var sprite: Character { sprites[frame] }
}


protocol Movable: Entity {
    var position: Int { get }
    func position(_ x: Int) -> Movable
}

extension Movable {
    func moved(_ dx: Int) -> Movable {
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

protocol Faced: Entity {
    var facing: Facing { get }
}

extension Faced where Self: Movable {
    func movedForward() -> Movable {
        return moved(facing == .right ? +1 : -1)
    }
    
    func movedBackward() -> Movable {
        return moved(facing == .right ? -1 : +1)
    }
}


// ENTITIES ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// TODO: Automatically deriving a builder pattern such as in https://github.com/colin-kiegel/rust-derive-builder would be wonderful
public class Actor: Entity, Movable, CharacterSprite, Agent {
        
    let sprite: Character
    let position: Int
        
    public init(position x: Int = 10, face f: Character = "😐") {
        self.position = x
        self.sprite = f
        
        super.init()
    }
    
    func sprite(_ f: Character) -> Actor {
        return Actor(position: self.position, face: f)
    }
    
    func position(_ x: Int) -> Movable {
        return Actor(position: x, face: self.sprite)
    }
        
    func update(dx: Int, face: Character?) -> (Entity, message: ((World) -> World)?) {
        let actor = self
            .moved(dx)
            |> { $0.position(clamp($0.position, min: 0, max: 63)) }
            |> { $0 as! Actor }
            |> { $0.sprite(face ?? $0.sprite) }
        
        if dx.magnitude >= 3 {
            let bullet = Bullet(position: actor.position, facing: dx > 0 ? .right : .left)
            //print(bullet.uuid)
            let spawnMessage = { (world: World) -> World in
                world.spawn(entity: bullet)
            }
            
            return (actor, spawnMessage)
        }
        
        return (actor, nil)
    }
    
}


public class Enemy: Entity, Faced, Movable, CharacterSprite, IndependentPatient {
    
    let position: Int
    let facing: Facing
    
    let sprite: Character = "😈"
    
    public init(position x: Int = 60, facing f: Facing = .left) {
        self.position = x
        self.facing = f
        
        super.init()
    }
    
    func position(_ x: Int) -> Movable {
        return Enemy(position: x, facing: self.facing)
    }
    
    func turned() -> Enemy {
        return Enemy(position: self.position, facing: self.facing.flipped())
    }
    
    func update() -> Entity {
        self.movedForward() as! Enemy
        |> { (enemy: Enemy) -> Entity in
            if enemy.position == 63 || enemy.position == 0 { return enemy.turned() }
            return enemy
        }
    }
    
}


public class Bullet: Entity, Faced, Movable, CharacterSprite, Agent {
    
    let position: Int
    let facing: Facing
    
    var sprite: Character { facing == .right ? "👉" : "👈" }
    
    init(position: Int, facing: Facing) {
        self.position = position
        self.facing = facing
        
        super.init()
    }
    
    func position(_ x: Int) -> Movable {
        return Bullet(position: x, facing: self.facing)
    }
    
    func turned() -> Bullet {
        return Bullet(position: self.position, facing: self.facing.flipped())
    }
    
    func update() -> (Entity, message: Message?) {
        self.movedForward() as! Bullet
        |> { (bullet: Bullet) -> (Entity, Message?) in
            if bullet.position == -1 || bullet.position == 64 {
                return (bullet, { $0.kill(bullet) })
            }
            return (bullet, nil)
        }
    }
    
    func update(dx: Int, face: Character?) -> (Entity, message: Message?) {
        let (entity, message): (Entity, Message?)
        switch face {
            /*
        case "😡": (entity, message) = (self, { (world: World) -> World in
            if Int.random(in: 0...2) == 0 { return world.kill(self) }
            return world
        })
            
        case "🤔": (entity, message) = (self.movedForward(), nil)
            */
        case "😳": (entity, message) = (self, { (world: World) -> World in
            let player: Actor = world.retain()[0]
            let dx = self.position - player.position
            
            if dx.signum() == self.facing.numeric {
                return world
                    .kill(self)
                    |> { $0.spawn(entity: self.turned().movedForward()) }
            }
            
            return world
        })
            
        default: (entity, message) = (self.movedForward(), nil)
        }

                
        let bullet = entity as! Bullet
        
        let spawnSmokeTrail = { (world: World) -> World in world.spawn(entity: SmokeTrail(position: bullet.position - bullet.facing.numeric)) }
        
        if bullet.position == -1 || bullet.position == 64 {
            return (entity, message >>> { $0.kill(entity) } >>> spawnSmokeTrail)
        }
        
        return (entity, message >>> spawnSmokeTrail)
    }
    
}


class SmokeTrail: Entity, AnimatedSprite {
    
    let sprites: [Character] = ["b", "u", "l", "l", "e", "t"]
    let frame: Int
    let position: Int
    
    init(frame: Int = -1, position: Int) {
        self.frame = frame
        self.position = position
    }
    
    func nextFrame() -> AnimatedSprite {
        return SmokeTrail(frame: self.frame + 1, position: self.position)
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
