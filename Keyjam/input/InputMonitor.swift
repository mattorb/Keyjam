import Combine
import Foundation

protocol InputMonitor {
  var eventPublisher: PassthroughSubject<StreakInEvent, Never> { get }
  func start() -> Bool
  func stop()
}
