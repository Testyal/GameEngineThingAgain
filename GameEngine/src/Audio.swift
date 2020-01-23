//
//  Audio.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 23/01/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation

// AUDIO //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typealias WhateverARealSoundObjectIs = Int

protocol Playable {
    func play() -> WhateverARealSoundObjectIs
}

struct SoundObject: Playable {
    
    func play() -> WhateverARealSoundObjectIs {
        return 0
    }
    
}


protocol AudioSystem {
    func doPlaySounds(sounds playableObjects: [Playable])
}

class DefaultAudioSystem: AudioSystem {
    
    func doPlaySounds(sounds pos: [Playable]) {
        pos.forEach { po in
            print("Sound played: po.play()")
        }
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
