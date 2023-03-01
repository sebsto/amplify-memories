//
//  Model.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 01/03/2023.
//

import Foundation

struct Memory {
    
    private(set) var data: MemoryData

    init(from: MemoryData) {
        self.data = from
    }
    
}


