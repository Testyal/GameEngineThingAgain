//
//  Input.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 23/01/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation

// INPUT //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

enum Input: CustomStringConvertible {
    
    case KEY_F
    case KEY_R
    case KEY_T
    case KEY_LEFT
    case KEY_RIGHT
    
    var description: String {
        switch self {
        case .KEY_F: return "F"
        case .KEY_R: return "R"
        case .KEY_T: return "T"
        case .KEY_LEFT: return "⬅️"
        case .KEY_RIGHT: return "➡️"
        }
    }
    
}


protocol InputProvider {
    func askInput() -> [Input]
}


class EmptyInputProvider: InputProvider {
    
    func askInput() -> [Input] {
        return []
    }
    
}


class RandomInputProvider: InputProvider {
    
    func askInput() -> [Input]{
        switch Int.random(in: 0...5) {
        case 1: return [.KEY_LEFT]
        case 2: return [.KEY_RIGHT]
        case 3: return [.KEY_F]
        case 4: return [.KEY_R]
        case 5: return [.KEY_T]
        default: return []
        }
    }
    
}


class InputLoop {
    
    private var inputBuffer: [[Input]]
    let inputProvider: InputProvider
    let timer: DispatchSourceTimer
    
    let dsema: DispatchSemaphore = DispatchSemaphore(value: 1)
    
    init(inputProvider ip: InputProvider, inputFrameTime ft: DispatchTimeInterval) {
        inputBuffer = []
        inputProvider = ip
        
        timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInteractive))
        timer.setEventHandler { [unowned self] in
            self.dsema.wait()
            self.inputBuffer = self.loop(self.inputBuffer)
            self.dsema.signal()
        }
        timer.schedule(deadline: .now(), repeating: ft, leeway: .milliseconds(1))
    }
    
    init() {
        inputBuffer = []
        inputProvider = RandomInputProvider()
        
        timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInteractive))
        timer.setEventHandler { [unowned self] in
            self.dsema.wait()
            self.inputBuffer = self.loop(self.inputBuffer)
            self.dsema.signal()
        }
        timer.schedule(deadline: .now(), repeating: .milliseconds(10), leeway: .milliseconds(1))
    }
    
    func loop(_ buffer: [[Input]]) -> [[Input]] {
        return buffer + [inputProvider.askInput()]
    }
    
    func doBeginLoop() {
        timer.resume()
    }
    
    func requestInputBuffer(_ handler: @escaping ([[Input]]) -> Void) {
        DispatchQueue.global(qos: .default).async { [unowned self] in
            self.dsema.wait()
            print("doing requested work with the input buffer")
            handler(self.inputBuffer)
            self.inputBuffer = []
            print("ending requested work with the input buffer")
            self.dsema.signal()
        }
    }
    
    func requestInputBuffer() -> [[Input]] {
        dsema.wait()
        let buffer = inputBuffer
        self.inputBuffer = []
        dsema.signal()
        
        return buffer
    }
    
}


class InputSystem {
    
    let inputLoop: InputLoop
    
    init() {
        inputLoop = InputLoop(inputProvider: RandomInputProvider(), inputFrameTime: .milliseconds(5))
    }
    
    func requestInputBuffer(_ handler: @escaping ([[Input]]) -> Void) {
        inputLoop.requestInputBuffer(handler)
    }
    
    func requestInputBuffer() -> [[Input]] {
        return inputLoop.requestInputBuffer()
    }
    
    func startInputLoop() {
        inputLoop.doBeginLoop()
    }
    
    static func scheduleInputLoop() -> InputSystem {
        let inputSystem = InputSystem()
        inputSystem.inputLoop.doBeginLoop()
        
        return inputSystem
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
