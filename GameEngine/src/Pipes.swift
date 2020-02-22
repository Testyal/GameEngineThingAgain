//
//  Pipes.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 11/02/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

precedencegroup ForwardPipe {
    higherThan: AssignmentPrecedence
    associativity: left
}

infix operator |> : ForwardPipe

public func |><T,U>(value: T, function: (T) -> U) -> U {
    return function(value)
}

/// i want documentation for operators pls
public func |><T,U>(value: T?, function: (T) -> U) -> U? {
    if let v = value {
        return function(v)
    } else {
        return nil
    }
}

infix operator >>> : ForwardPipe

public func >>><T,U,V>(f: @escaping (T) -> U, g: @escaping (U) -> V) -> ((T) -> V) {
    return { g(f($0)) }
}

public func >>><T>(f: ((T) -> T)?, g: ((T) -> T)?) -> ((T) -> T)? {
    if f == nil && g == nil { return nil }
    if f == nil && g != nil { return g! }
    if f != nil && g == nil { return f! }
    return { g!(f!($0)) }
}


precedencegroup BackwardPipe {
    higherThan: AssignmentPrecedence
    associativity: right
}

infix operator <| : BackwardPipe

public func <|<T,U>(function: (T) -> U, value: T) -> U {
    return function(value)
}

public func <|<T,U>(function: (T) -> U, value: T?) -> U? {
    if let v = value {
        return function(v)
    } else {
        return nil
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

