//
//  Input.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 23/01/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation

// INPUT //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public enum Input {
    case KEY_A
    case KEY_LEFT
    case KEY_RIGHT
}


protocol InputSystem {
    func askInput() -> Input?
}

class EmptyInputSystem: InputSystem {
    
    func askInput() -> Input? {
        return nil
    }
    
}

class RandomInputSystem: InputSystem {
    
    func askInput() -> Input? {
        switch Int.random(in: 0...2) {
        case 1: return .KEY_LEFT
        case 2: return .KEY_RIGHT
        default: return nil
        }
    }
    
}


protocol InputProvider {
    func askInput() -> Input?
}

class RandomInputProvider: InputProvider {
    
    func askInput() -> Input? {
        switch Int.random(in: 1...2) {
        case 1: return .KEY_LEFT
        case 2: return .KEY_RIGHT
        default: return nil
        }
    }
    
}


public class InputLoop {
    
    private var inputBuffer: [Input]
    let inputProvider: InputProvider
    let timer: DispatchSourceTimer
    
    let dsema: DispatchSemaphore = DispatchSemaphore(value: 1)
    
    public init() {
        inputBuffer = []
        inputProvider = RandomInputProvider()
        
        timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInteractive))
        timer.setEventHandler { [unowned self] in
            self.dsema.wait()
            self.inputBuffer = self.loop(self.inputBuffer)
            print("buffer updated")
            self.dsema.signal()
        }
        timer.schedule(deadline: .now(), repeating: .milliseconds(1000), leeway: .milliseconds(1))
    }
    
    func loop(_ buffer: [Input]) -> [Input] {
        if let i = inputProvider.askInput() {
            return buffer + [i]
        } else {
            return buffer
        }
    }
    
    public func doBeginLoop() {
        timer.resume()
    }
    
    public func requestInputBuffer(_ handler: @escaping ([Input]) -> Void) {
        print("work is being requested")
        DispatchQueue.global(qos: .default).async { [unowned self] in
            self.dsema.wait()
            handler(self.inputBuffer)
            self.inputBuffer = []
            self.dsema.signal()
        }
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
