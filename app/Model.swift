//
//  Model.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 01/03/2023.
//

import Foundation
import Logging
import CoreLocation

import Collections

struct Memory: Identifiable {
    
    private var logger = Logger(label: "\(PACKAGE_NAME).Memory")
    public let validStarRange = 0...5

    var id = UUID() // iternal only, just to be Identifiable
    
    public let owner: String
    public let moment: String
    public let description: String
    public let image: String
    public var star: Int
    public var favourite: Bool
    public let coordinates: Coordinates
    public let imageURL: URL?
    
    init(owner: String,
         moment: Date = .now,
         description: String = "",
         image: String,
         star: Int = 0,
         favourite: Bool = false,
         coordinate: Coordinates) {
#if DEBUG
        self.logger.logLevel = .debug
#endif

        let momentAsString = moment.toMoment()
        self.owner = owner
        self.moment = momentAsString
        self.description = description
        self.image = image
        self.star = star
        self.favourite = favourite
        self.coordinates = coordinate
        
        self.imageURL = Memory.computeImageURL(for: image, with: logger)
    }
    
    private static func computeImageURL(for image: String, with logger: Logger) -> URL? {
                
        var result : URL?
        
        // mocked data have image name like "landscape1.png"
        // real data have image name like "400E3677-3670-46EF-95E6-586918C1439A"
        let split = image.split(separator: ".")
        if split.count == 2 && split[1] == "png" {
            logger.debug("Mocked data, going to return URL for \(split)")
            result = Bundle.main.url(forResource: String(split[0]), withExtension: String(split[1]))
        } else {
            logger.debug("Real data, computing URL")
            result = nil
        }
        return result
    }

    mutating func star(count: Int) {
        guard validStarRange ~= count else {
            return
        }
        self.star = count
    }
    
    fileprivate var year : Int {
        guard let result = Int(self.moment.prefix(4)) else {
            fatalError("Can not extract year from moment: \(self.moment)")
        }
        return result
    }
    
    static func yearsAgo(_ year: Int) -> String {
        let thisYear = Calendar.current.component(.year, from: .now)
        let elapsed = thisYear - year
        return "\(elapsed) \(elapsed > 1 ? "years" : "year") ago"
    }
    func yearsAgo() -> String {
        return Memory.yearsAgo(self.year)
    }

    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude)
    }
}

//MARK: bridge between app model and backend model
extension Memory {
    
    init(from: MemoryData) {
        
        if let date = from.moment.toDate() {
            let coordinates = Coordinates(from: from.coordinates)
            self.init(owner: from.owner,
                      moment: date,
                      description: from.description ?? "",
                      image: from.image,
                      star: from.star,
                      favourite: from.favourite,
                      coordinate: coordinates)
        } else {
            fatalError("Date from database can not be converted to a date: \(from.moment)")
        }
    }
    
    var data: MemoryData {
        let cd = CoordinateData(longitude: self.coordinates.longitude,
                                latitude: self.coordinates.latitude)
        return MemoryData(owner: self.owner,
                          moment: self.moment,
                          image: self.image,
                          star: self.star,
                          favourite: self.favourite,
                          coordinates: cd)
    }
}

extension Date {
    func toMoment() -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyyMMddHHmmss"
        displayFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return displayFormatter.string(from: self)
    }
}

extension String {
    func toDate() -> Date? {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyyMMddHHmmss"
        displayFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return displayFormatter.date(from: self)
    }
}

//extension Array<Memory> {
//    func groupByYears() -> OrderedDictionary<Int, [Memory]> {//[Int:[Memory]] {
//
//        var result : OrderedDictionary<Int, [Memory]> = [:]
//        // group all memories per year.
//        // result is [ "2023" : [m1, m3], "2022" : [m2] ]
//        for m in self {
//
//            let year = m.year
//            if result.keys.contains(year) {
//                var memories = result[year]!
//                memories.append(m)
//                result[year] = memories
//            } else {
//                result[year] = [m]
//            }
//        }
//        return result
//    }
//}

// MARK: functions to support filtering and grouping of memories
// this is used bu the GUI for presentation purposes
extension Array<Memory> {
    func groupByYears() -> [Int:[Memory]] {
        
        var result : [Int:[Memory]] = [:]
        // group all memories per year.
        // result is [ "2023" : [m1, m3], "2022" : [m2] ]
        for m in self {
            
            let year = m.year
            if result.keys.contains(year) {
                var memories = result[year]!
                memories.append(m)
                result[year] = memories
            } else {
                result[year] = [m]
            }
        }
        return result
    }
    
    func years() -> [Int] {
        let dict = self.groupByYears()
        let result = dict.map { $0.key } // convert to array of keys
        return result.sorted(by: {
            (lv, rv) in lv > rv
        })
    }
}


struct Coordinates: Hashable, Codable {
    init(from: CoordinateData) {
        self.longitude = from.longitude
        self.latitude = from.latitude
    }
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    var latitude: Double
    var longitude: Double
}
