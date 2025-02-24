import Foundation

extension KeyjamApp {
  func initializeDependencies(container: DependencyContainer) {
    let repository = StreakRepository()
    container.registerSingleton(type: StreakRepository.self) { repository }

    let coordinator = StreakCoordinator(repository: repository)
    container.registerSingleton(type: StreakCoordinator.self) { coordinator }
  }
}
