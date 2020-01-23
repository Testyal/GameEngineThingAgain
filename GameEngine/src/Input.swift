//
//  Input.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 23/01/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation

// INPUT //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

enum Input {
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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
