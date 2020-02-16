//
//  Math.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 15/02/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation

func clamp(_ x: Int, min minVal: Int, max maxVal: Int) -> Int {
    return min(max(x, minVal), maxVal)
}
