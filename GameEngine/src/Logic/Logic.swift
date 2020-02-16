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
    
    let player: Actor
    let enemy: Enemy
    let frame: Int
    
    public init() {
        self.player = Actor()
        self.enemy = Enemy()
        self.frame = 0
    }
    
    public init(player p: Actor, enemy e: Enemy, frame fr: Int) {
        self.player = p
        self.enemy = e
        self.frame = fr
    }
    
    func player(_ p: Actor) -> World {
        return World(player: p, enemy: self.enemy, frame: self.frame)
    }
    
    func enemy(_ e: Enemy) -> World {
        return World(player: self.player, enemy: e, frame: self.frame)
    }
    
    func nextFrame() -> World {
        return World(player: self.player, enemy: self.enemy, frame: self.frame + 1)
    }
    
}


protocol LogicSystem {
    func update(dt deltaTime: Double, input: [[Input]], world frameData: World) -> (renderables: [Renderable], playables: [Playable], world: World)
}

class DefaultLogicSystem: LogicSystem {
    
    let inputParser = InputParser()
    
    func update(dt deltaTime: Double, input: [[Input]], world: World) -> (renderables: [Renderable], playables: [Playable], world: World) {
        let (dx, newFace) = inputParser.parse(input)
        let face = newFace ?? world.player.sprite
    
        let player = world.player
            .moved(dx)
            .sprite(face)
            |> { $0.position(clamp($0.position, min: 0, max: 63)) }
        
        let enemy = world.enemy
            .movedForward()
            |> { (e: Enemy) -> Enemy in
                if e.position == 0 || e.position == 63 { return e.turned() }
                return e
            }
        
        let world = world
            .player(player)
            .enemy(enemy)
            .nextFrame()
        
        let rs: [Renderable] = [BackgroundRenderObject("."),
                                player.asRenderObject(),
                                enemy.asRenderObject(),
                                TextLineRenderObject("\(input.description): dx = \(dx)"),
                                TextLineRenderObject("Frame: \(world.frame)")]
        
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


protocol CharacterAsTextRenderObject {
    var sprite: Character { get }
    var position: Int { get }
}

extension CharacterAsTextRenderObject {
    func asRenderObject() -> TextRenderObject {
        return TextRenderObject(String(sprite), at: position)
    }
}


protocol Movable {
    associatedtype Moved
    var position: Int { get }
    func position(_ x: Int) -> Moved
}

extension Movable {
    func moved(_ dx: Int) -> Moved {
        return position(position + dx)
    }
}

// TODO: Automatically deriving a builder pattern such as in https://github.com/colin-kiegel/rust-derive-builder would be wonderful
public class Actor: Movable, CharacterAsTextRenderObject {
    
    let sprite: Character
    let position: Int
    
    init() {
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
}

public class Enemy: FacedMovable, CharacterAsTextRenderObject {
    
    let position: Int
    let facing: Facing
    
    let sprite: Character = "😈"
    
    init() {
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
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

