import Foundation

@Observable
final class StreakRepository {
  private(set) var keyCount: Int = 0
  private(set) var mouseBreak: Int = 0
  private(set) var streakEvents: [StreakEvent] = []

  // Maximum age of stored events (one month)
  private let maxEventAge: TimeInterval = 30 * 24 * 60 * 60  // 30 days in seconds

  init() {
    loadStreakEvents()
  }

  func incrementKeyCount() {
    keyCount += 1
  }

  func resetKeyCount() -> Int {
    let count = keyCount
    keyCount = 0

    // Only record significant streaks (e.g., more than 3 keystrokes)
    if count > 3 {
      recordStreakEvent(count: count)
    }

    return count
  }

  func incrementMouseBreak() {
    mouseBreak += 1
  }

  private func recordStreakEvent(count: Int) {
    let event = StreakEvent(streakCount: count)
    streakEvents.append(event)

    // Clean up old events
    removeExpiredEvents()

    saveStreakEvents()
  }

  private func removeExpiredEvents() {
    let cutoffDate = Date().addingTimeInterval(-maxEventAge)
    streakEvents = streakEvents.filter { $0.timestamp >= cutoffDate }
  }

  func loadStreakEvents() {
    streakEvents = FileManager.loadStreakEvents()

    // Remove any expired events during load
    removeExpiredEvents()
  }

  private func saveStreakEvents() {
    FileManager.saveStreakEvents(streakEvents)
  }

  // Returns streak events for the specified time period
  func getRecentStreakEvents(days: Int = 7) -> [StreakEvent] {
    let calendar = Calendar.current
    let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

    // Filter events from the last 'days' days and sort by timestamp
    return
      streakEvents
      .filter { $0.timestamp >= startDate }
      .sorted { $0.timestamp < $1.timestamp }
  }
}
