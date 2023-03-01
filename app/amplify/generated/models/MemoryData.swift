// swiftlint:disable all
import Amplify
import Foundation

public struct MemoryData: Model {
  public let owner: String
  public let moment: String
  public var description: String?
  public var image: String?
  public var star: Int?
  public var favourite: Bool?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(owner: String,
      moment: String,
      description: String? = nil,
      image: String? = nil,
      star: Int? = nil,
      favourite: Bool? = nil) {
    self.init(owner: owner,
      moment: moment,
      description: description,
      image: image,
      star: star,
      favourite: favourite,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(owner: String,
      moment: String,
      description: String? = nil,
      image: String? = nil,
      star: Int? = nil,
      favourite: Bool? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.owner = owner
      self.moment = moment
      self.description = description
      self.image = image
      self.star = star
      self.favourite = favourite
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}