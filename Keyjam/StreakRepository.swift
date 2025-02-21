import Foundation

@Observable
final class StreakRepository {
  nonisolated(unsafe) public static let shared: StreakRepository = .init()

  public var keyCount: Int = 0
  public var mouseBreak: Int = 0
}
