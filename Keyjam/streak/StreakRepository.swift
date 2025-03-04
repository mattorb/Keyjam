import Foundation

@Observable
final class StreakRepository {
  private(set) var keyCount: Int = 0
  private(set) var mouseBreak: Int = 0
  private(set) var streakEvents: [StreakEvent] = []

  private let maxStoredEvents = 100

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

    // Limit the number of stored events
    if streakEvents.count > maxStoredEvents {
      streakEvents.sort { $0.timestamp > $1.timestamp }  // Sort by timestamp descending
      streakEvents = Array(streakEvents.prefix(maxStoredEvents))
    }

    saveStreakEvents()
  }

  private func loadStreakEvents() {
    streakEvents = FileManager.loadStreakEvents()
  }

  private func saveStreakEvents() {
    FileManager.saveStreakEvents(streakEvents)
  }

  // Returns streak events for the last 7 days
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
