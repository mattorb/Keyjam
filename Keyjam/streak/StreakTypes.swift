import Foundation

enum StreakInEvent {
  case commonKeyPress
  case shortcutKeyPress
  case mouseMoveStarted
}

enum StreakOutEvent: Equatable {
  case reset
  case increased
  case decreased
  case mouseBrokeStreak(keyCount: Int)
}

enum StreakContext {
  case all
  case apps(named: [String])
}

struct StreakEvent: Identifiable, Codable, Equatable {
  let id: UUID
  let timestamp: Date
  let streakCount: Int

  init(id: UUID = UUID(), timestamp: Date = Date(), streakCount: Int) {
    self.id = id
    self.timestamp = timestamp
    self.streakCount = streakCount
  }
}
