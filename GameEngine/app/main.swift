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

let world = World([:]).spawn(entity: Node(patient: EmptyPatient(id: UUID()),
                                          children: [ Node(patient: NewBullet(id: UUID(), position: 0), children: []),
                                                      Node(patient: Printer(id: UUID()), children: [])
                                                    ]))

engine.doStartGame(initialWorld: world)

// Gross hack please fix :(
while true {}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
