import Combine
import CoreGraphics
import Foundation

class MouseMonitor: InputMonitor {
  let eventPublisher = PassthroughSubject<StreakInEvent, Never>()
  private var eventTap: CFMachPort?

  func start() {
    let eventMask: CGEventMask =
      (1 << CGEventType.mouseMoved.rawValue) | (1 << CGEventType.leftMouseDragged.rawValue) | (1 << CGEventType.rightMouseDragged.rawValue)

    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: eventMask,
        callback: { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
          let monitor = Unmanaged<MouseMonitor>.fromOpaque(userInfo!).takeUnretainedValue()

          if type == .mouseMoved || type == .leftMouseDragged || type == .rightMouseDragged {
            monitor.eventPublisher.send(.mouseMoveStarted)
          }
          return Unmanaged.passUnretained(event)
        },
        userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
      )
    else {
      fatalError("Failed to create mouse event tap")
    }

    self.eventTap = eventTap
    let runLoopSource = CFMachPortCreateRunLoopSource(
      kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(
      CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
  }

  func stop() {
    guard let eventTap = eventTap else { return }
    CGEvent.tapEnable(tap: eventTap, enable: false)
  }
}
