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
}

extension Entity {
    public var name: String { "Untitled \(Self.self)" }
    var hash: Int { name.hashValue }
    
    static func ==(_ e1: Entity, _ e2: Entity) -> Bool {
        return e1.hash == e2.hash
    }
}


protocol Patient: Entity {
    func update() -> (Entity, message: Message?)
}

protocol Agent: Entity {
    func update(dx: Int, face: Character) -> (Entity, message: Message?)
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


protocol Movable: Entity {
    associatedtype Moved
    var position: Int { get }
    func position(_ x: Int) -> Moved
}

extension Movable {
    func moved(_ dx: Int) -> Moved {
        return position(position + dx)
    }
}


enum Facing {
    case left
    case right
    
    func flipped() -> Facing {
        return self == .left ? .right : .left
    }
}

protocol FacedMovable: Movable {
    var facing: Facing { get }
}

extension FacedMovable {
    func movedForward() -> Moved {
        return moved(facing == .right ? +1 : -1)
    }
    
    func movedBackward() -> Moved {
        return moved(facing == .right ? -1 : +1)
    }
}

// ENTITIES ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// TODO: Automatically deriving a builder pattern such as in https://github.com/colin-kiegel/rust-derive-builder would be wonderful
public struct Actor: Movable, CharacterSprite, Agent {
    
    let sprite: Character
    let position: Int
    
    let i: Int = 0
    
    public init() {
        self.position = 0
        self.sprite = "😐"
    }
    
    init(position x: Int, face f: Character) {
        self.position = x
        self.sprite = f
    }
    
    func sprite(_ f: Character) -> Actor {
        return Actor(position: self.position, face: f)
    }
    
    func position(_ x: Int) -> Actor {
        return Actor(position: x, face: self.sprite)
    }
        
    func update(dx: Int, face: Character) -> (Entity, message: ((World) -> World)?) {
        let actor = self
            .moved(dx)
            .sprite(face)
            |> { $0.position(clamp($0.position, min: 0, max: 63)) }
        
        var message: ((World) -> World)? = nil
        if actor.position == 15 {
            message = { $0.spawn(entity: Bullet(name: "funny bullet", position: self.position, facing: .right)) }
        }
            
        return (actor, message: message)
    }
    
}


public struct Enemy: FacedMovable, CharacterSprite, Patient {
    
    let position: Int
    let facing: Facing
    
    let sprite: Character = "😈"
    
    public init() {
        self.position = 60
        self.facing = .left
    }
    
    init(position x: Int, facing f: Facing) {
        self.position = x
        self.facing = f
    }
    
    func position(_ x: Int) -> Enemy {
        return Enemy(position: x, facing: self.facing)
    }
    
    func turned() -> Enemy {
        return Enemy(position: self.position, facing: self.facing.flipped())
    }
    
    func update() -> (Entity, message: Message?) {
        let movedForward = self.movedForward()
        
        if movedForward.position == 63 || movedForward.position == 0 {
            return (movedForward.turned(), nil)
        } else {
            return (movedForward, nil)
        }
    }
    
}


public struct Bullet: FacedMovable, CharacterSprite, Patient {
    
    public let name: String
    let position: Int
    let facing: Facing
    
    var sprite: Character { facing == .right ? "👉" : "👈" }
    
    init(name: String = "Unnamed Bullet", position: Int, facing: Facing) {
        self.name = name
        self.position = position
        self.facing = facing
    }
    
    func position(_ x: Int) -> Bullet {
        return Bullet(position: x, facing: self.facing)
    }
    
    func update() -> (Entity, message: Message?) {
        let updatedSelf = self.movedForward()
        
        guard updatedSelf.position < 64 else { return (self, message: { $0.kill(self.name) }) }
        
        return (updatedSelf, nil)
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
