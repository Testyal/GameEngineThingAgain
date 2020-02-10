//
//  Render.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 23/01/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation

// RENDER /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typealias RenderInstruction = (ConsoleRenderer, [Character]) -> [Character]


protocol Renderable {
    func render() -> [RenderInstruction]
}

class TextLineRenderObject: Renderable {
    
    let value: String
    
    init(_ v: String) {
        self.value = v
    }
    
    func render() -> [RenderInstruction] {
        return [{(r, s) in r.writeLine(text: self.value, onto: s)}]
    }
    
}


class TextRenderObject: Renderable {
    
    let value: String
    let position: Int
    
    init(_ v: String, at x: Int) {
        self.value = v
        self.position = x
    }
    
    func render() -> [RenderInstruction] {
        return [{(r, s) in r.write(text: self.value, at: self.position, onto: s)}]
    }
    
}


class CharacterRenderObject: Renderable {
    
    let value: Character
    let position: Int
    
    init(_ c: Character, at x: Int) {
        self.value = c
        self.position = x
    }
    
    func render() -> [RenderInstruction] {
        return [{(r, s) in r.putCharacter(self.value, at: self.position, onto: s)}]
    }
    
}


class BackgroundRenderObject: Renderable {
    
    let value: Character
    
    init(_ c: Character) {
        self.value = c
    }
    
    func render() -> [RenderInstruction] {
        return [{(r, s) in r.clearScreen(withCharacter: self.value, onto: s)}]
    }
    
}


class BackgroundPatternRenderObject: Renderable {
    
    let pattern: String
    
    init(_ p: String) {
        self.pattern = p
    }
    
    func render() -> [RenderInstruction] {
        return [{(r, s) in r.clearScreen(withPattern: self.pattern, onto: s)}]
    }
    
}


class ConsoleRenderer {
    
    func write(text t: String, at x: Int, onto s: [Character]) -> [Character] {
        let cc: [Character] = Array(t)
        var s2 = s
        
        for i in 0..<cc.count {
            s2[x + i] = cc[i]
        }
        
        return s2
    }
    
    func writeLine(text t: String, onto s: [Character]) -> [Character] {
        return s + "\n" + t
    }
    
    func clearScreen(withCharacter c: Character, onto s: [Character]) -> [Character] {
        return [Character](repeating: c, count: 64)
    }
    
    func clearScreen(withPattern p: String, onto s: [Character]) -> [Character] {
        let len = p.count
        return Array(String(repeating: p, count: max(64/len + 1, 1)).prefix(64))
    }
    
    func putCharacter(_ c: Character, at x: Int, onto s: [Character]) -> [Character] {
        assert(0 <= x && x < 64)
        var os = s
        os[x] = c
        return os
    }
    
}


protocol RenderSystem {
    func doRender(objects oo: [Renderable])
}

class ConsoleRenderSystem: RenderSystem {
    
    let renderer = ConsoleRenderer()
    
    func render(instructions ii: [RenderInstruction]) -> [Character] {
        let blank = [Character](repeating: " ", count: 64)
        return ii.reduce(blank) { (v,f) -> [Character] in
            return f(renderer,v)
        }
    }
    
    func convertToRenderCode(objects oo: [Renderable]) -> [RenderInstruction] {
        return oo.flatMap { o in
            o.render()
        }
    }
    
    func doRender(objects oo: [Renderable]) {
        let output = render(instructions: convertToRenderCode(objects: oo))
        print(String(output))
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
