//
//  ModelMock.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 02/03/2023.
//

import Foundation

extension Memory {
    
    public static func mockCoordinates() -> Coordinates {
        let randomLat = Double.random(in: -0.3...0.3)
        let randomLong = Double.random(in: -0.3...0.3)
        return Coordinates(latitude: 50.6292 + randomLat,
                           longitude: 3.0573 + randomLong)
    }
    
    public static let mock: [Memory] = [
        
        
        Memory(owner: "me", moment: "20220301123456".toDate()!,
               description: """
This is my description for memory #1.
It is a long description multiple lines.  I wonder how the text will render.
""",
               image: "landscape1.png", star: 0, favourite: true,
               coordinate: mockCoordinates()),
        
        Memory(owner: "me", moment: "20220301163456".toDate()!,
               description: "This is my description for memory #2",
               image: "landscape2.png", star: 1, favourite: false,
               coordinate: mockCoordinates()),
        
        Memory(owner: "me", moment: "20210302123456".toDate()!,
               description: "This is my description for memory #3",
               image: "landscape3.png", star: 2, favourite: true,
               coordinate: mockCoordinates()),
        
        Memory(owner: "me", moment: "20210302163456".toDate()!,
               description: "This is my description for memory #4",
               image: "landscape4.png", star: 3, favourite: false,
               coordinate: mockCoordinates()),
        
        Memory(owner: "me", moment: "20200303123456".toDate()!,
               description: "This is my description for memory #5",
               image: "landscape5.png", star: 4, favourite: true,
               coordinate: mockCoordinates()),
        
        Memory(owner: "me", moment: "20190303163456".toDate()!,
               description: "This is my description for memory #6",
               image: "landscape6.png", star: 5, favourite: false,
               coordinate: mockCoordinates()),
    ]
}
