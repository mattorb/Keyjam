import Foundation

@Observable
final class StreakRepository {
  private(set) var keyCount: Int = 0
  private(set) var mouseBreak: Int = 0

  func incrementKeyCount() {
    keyCount += 1
  }

  func resetKeyCount() -> Int {
    let count = keyCount
    keyCount = 0
    return count
  }

  func incrementMouseBreak() {
    mouseBreak += 1
  }
}
