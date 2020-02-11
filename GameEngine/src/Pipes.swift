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

public func |><T,U>(value: T?, function: (T) -> U) -> U? {
    if let v = value {
        return function(v)
    } else {
        return nil
    }
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

