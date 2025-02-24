import Combine
import Foundation

final class StreakEngine {
  private let repository: StreakRepository

  init(repository: StreakRepository) {
    self.repository = repository
  }

  func processKeyPress() -> StreakOutEvent {
    repository.incrementKeyCount()
    return .increased
  }

  func processMouseMove() -> StreakOutEvent {
    if repository.keyCount > 0 {
      let keyCount = repository.resetKeyCount()
      repository.incrementMouseBreak()
      return .mouseBrokeStreak(keyCount: keyCount)
    }
    return .reset
  }
}
