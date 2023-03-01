// swiftlint:disable all
import Amplify
import Foundation

extension MemoryData {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case owner
    case moment
    case description
    case image
    case star
    case favourite
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let memoryData = MemoryData.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.syncPluralName = "MemoryData"
    
    model.attributes(
      .index(fields: ["owner", "moment"], name: nil),
      .primaryKey(fields: [memoryData.owner, memoryData.moment])
    )
    
    model.fields(
      .field(memoryData.owner, is: .required, ofType: .string),
      .field(memoryData.moment, is: .required, ofType: .string),
      .field(memoryData.description, is: .optional, ofType: .string),
      .field(memoryData.image, is: .optional, ofType: .string),
      .field(memoryData.star, is: .optional, ofType: .int),
      .field(memoryData.favourite, is: .optional, ofType: .bool),
      .field(memoryData.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(memoryData.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension MemoryData: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension MemoryData.IdentifierProtocol {
  public static func identifier(owner: String,
      moment: String) -> Self {
    .make(fields:[(name: "owner", value: owner), (name: "moment", value: moment)])
  }
}
