//
//  Bench.swift
//  GameEngineStuffForTheFiveThousandthTime
//
//  Created by Billy Sumners on 12/02/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

func displayBenchmark(of codeDescription: String, start: DispatchTime, end: DispatchTime) {
    print("\(codeDescription) finished in \((end.uptimeNanoseconds - start.uptimeNanoseconds)/1000) μs")
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
