// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "507d6a4a5b69514715bafb7244da0b88"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: MemoryData.self)
  }
}