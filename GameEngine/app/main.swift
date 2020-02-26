//
//  main.swift
//  SampleGame
//
//  Created by Billy Sumners on 22/01/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation
import Engine
import Pipes

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

let engine = Engine()

let world = World([:])
    .spawn(entity: Actor.new(sprite: "😐", position: 10))
    .spawn(entity: Enemy.new(name: "Enemy", position: 30, facing: .right))

engine.doStartGame(initialWorld: world)

// Gross hack please fix :(
while true {}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
