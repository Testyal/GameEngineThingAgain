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

let inputLoop = InputLoop()
let otherLoop = DispatchSource.makeTimerSource(queue: .global(qos: .default))

otherLoop.setEventHandler {
    print("hey")
    inputLoop.requestInputBuffer { (input) in
        if !input.isEmpty {
            print(input)
            print("there are \(input.count) values in the buffer")
        }
    }
}
otherLoop.schedule(deadline: .now(), repeating: .milliseconds(1000), leeway: .milliseconds(1))

inputLoop.doBeginLoop()
otherLoop.resume()

while true {}
