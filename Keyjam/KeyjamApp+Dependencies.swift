import Foundation

extension KeyjamApp {
  func initializeDependencies(container: DependencyContainer) {
    let repository = StreakRepository()
    container.registerSingleton(type: StreakRepository.self) { repository }

    let tracker = StreakTracker(repository: repository)
    container.registerSingleton(type: StreakTracker.self) { tracker }
  }
}
