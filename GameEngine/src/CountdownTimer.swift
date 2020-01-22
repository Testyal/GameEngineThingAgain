//
//  CountdownTimer.swift
//  BetterCountdownTimer
//
//  Created by Billy Sumners on 16/01/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Blah blah funny pee
// when the moon hits your eye
// so this is a story
// final line
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typealias Action = () -> Void

class CountdownTimer {
    
    let duration: Int
    let action: Action
    
    init(duration: Int, fire action: @escaping Action) {
        self.duration = duration
        self.action = action
    }
    
    static func spawnTimer(duration: Int, fire action: @escaping Action) -> CountdownTimer {
        let timer = CountdownTimer(duration: duration, fire: action)
        timer.start()
        
        return timer
    }
    
    func start() {
        let _ = Timer.scheduledTimer(withTimeInterval: TimeInterval(duration) * 0.001, repeats: false) { _ in
            self.action()
        }
    }
    
    func pause() {
        
    }
    
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

