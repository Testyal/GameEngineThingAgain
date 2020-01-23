//
//  Render.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 23/01/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation

// RENDER /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

protocol Renderable {
    func show() -> String
}

struct TextRenderObject: Renderable {
    
    let text: String
    
    func show() -> String {
        return text
    }
    
}


protocol RenderSystem {
    func doRender(objects renderableObjects: [Renderable])
}

class DefaultRenderSystem: RenderSystem {
    
    func doRender(objects ros: [Renderable]) {
        ros.forEach { ro in
            print(ro.show())
        }
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
