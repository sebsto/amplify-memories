//
//  GraphQLQueries.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 08/03/2023.
//

import Foundation
import Amplify

extension GraphQLRequest {
    static func getTodayMemory(owner: String) -> GraphQLRequest<[String:[MemoryData]]> {
        
        // from 20230308123456 to 0308
        let moment = Date.now.toMoment().prefix(8).suffix(4) // take just the MMDD portion
        
        let operationName = "listMemoryData"
        let document =
"""
query todayMemories($owner: String, $moment: String)  {
  \(operationName)(owner: $owner, moment: {beginsWith: $moment} ) {
    items {
      moment
      year
      owner
      createdAt
      coordinates {
        latitude
        longitude
      }
      description
      favourite
      image
      star
      updatedAt
    }
  }
}
"""
        
        return GraphQLRequest<[String:[MemoryData]]> (document: document,
                                           variables: [ "owner" : owner, "moment" : moment],
                                           responseType: [String:[MemoryData]].self,
                                           decodePath: operationName)
    }
}
