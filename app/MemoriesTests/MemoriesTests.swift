//
//  MemoriesTests.swift
//  MemoriesTests
//
//  Created by Stormacq, Sebastien on 23/02/2023.
//

import XCTest
@testable import Memories

final class MemoryModelTests: XCTestCase {
    
    let coordinates: Coordinates = Memory.mockCoordinates()

    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDateToMoment() {
        
        let srcDate = "2023-03-02 11:20:33 Z"
        let dstDate = "20230302112033"
        
        // given
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        displayFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let date = displayFormatter.date(from: srcDate)
        XCTAssertNotNil(date)
        
        // when
        let memory = Memory(owner: "owner",
                            moment: date!,
                            description: "description",
                            image: "image",
                            star: 0,
                            favourite: true,
                            coordinate: coordinates)
                            
        // then
        XCTAssertEqual(memory.moment, dstDate)
    }
    
    func testMomentToDate() {

        // given
        let srcDate = "20230302112033"
        
        // when
        let memory = Memory(owner: "owner",
                            moment: srcDate.toDate()!,
                            description: "description",
                            image: "image",
                            star: 0,
                            favourite: true,
                            coordinate: coordinates)

        // then
        XCTAssertNotNil(memory)
        XCTAssertEqual(memory.moment, srcDate)
    }

}
