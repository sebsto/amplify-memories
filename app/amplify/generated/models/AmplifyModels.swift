// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "fb2b61391d703ae00c5c12acd8e33e11"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: MemoryData.self)
  }
}