import Foundation
import SwiftUI

// Purpose built narrow DI for Observable singleton impl classes
class DependencyContainer {
  nonisolated(unsafe) public static let shared = DependencyContainer()

  private var singletons = [String: (AnyObject & Observable)]()

  func registerSingleton<T: AnyObject & Observable>(type: T.Type, _ factory: @escaping () -> T) {
    let key = String(describing: type)
    singletons[key] = factory()
  }

  func resolve<T: AnyObject & Observable>(type: T.Type) -> T? {
    let key = String(describing: type)
    if let singleton = singletons[key] as? T {
      return singleton
    }
    return nil
  }
}

// Easily inject via environment of Scene at app root
extension Scene {
  /// Inject dependency from container via SwiftUI to enable @Environment style lookup
  func environment<T: AnyObject & Observable>(_ type: T.Type, from container: DependencyContainer) -> some Scene {
    let resolvedValue = container.resolve(type: T.self)!
    return self.environment(resolvedValue)
  }
}
