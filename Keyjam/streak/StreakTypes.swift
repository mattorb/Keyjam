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
