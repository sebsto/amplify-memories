// swiftlint:disable all
import Amplify
import Foundation

public struct MemoryData: Model {
  public let owner: String
  public let moment: String
  public var year: String
  public var description: String?
  public var image: String
  public var star: Int
  public var favourite: Bool
  public var coordinates: CoordinateData?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(owner: String,
      moment: String,
      year: String,
      description: String? = nil,
      image: String,
      star: Int,
      favourite: Bool,
      coordinates: CoordinateData? = nil) {
    self.init(owner: owner,
      moment: moment,
      year: year,
      description: description,
      image: image,
      star: star,
      favourite: favourite,
      coordinates: coordinates,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(owner: String,
      moment: String,
      year: String,
      description: String? = nil,
      image: String,
      star: Int,
      favourite: Bool,
      coordinates: CoordinateData? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.owner = owner
      self.moment = moment
      self.year = year
      self.description = description
      self.image = image
      self.star = star
      self.favourite = favourite
      self.coordinates = coordinates
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}