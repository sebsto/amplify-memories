// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "c28fc28daa907f9200bc907b7aa17ab3"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: MemoryData.self)
  }
}