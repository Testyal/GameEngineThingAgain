//
//  main.swift
//  SampleGame
//
//  Created by Billy Sumners on 22/01/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation
import Engine

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

let engine = Engine()
engine.doStartGame(initialWorld: World(actorPosition: 0, actorFace: "o", frame: 0))


// Gross hack please fix :(
while true {}
