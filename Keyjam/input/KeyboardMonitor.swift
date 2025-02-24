import Combine
import CoreGraphics
import Foundation

class KeyboardMonitor: InputMonitor {
  let eventPublisher = PassthroughSubject<StreakInEvent, Never>()
  private var eventTap: CFMachPort?

  func start() {
    let eventMask = (1 << CGEventType.keyDown.rawValue)
    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask),
        callback: { proxy, type, event, userInfo in
          let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(userInfo!).takeUnretainedValue()

          if type == .keyDown {
            let flags = event.flags
            let shortcutMask: [CGEventFlags] = [.maskCommand, .maskControl, .maskAlternate, .maskHelp, .maskSecondaryFn]

            if !flags.intersection(CGEventFlags(shortcutMask)).isEmpty {
              monitor.eventPublisher.send(.shortcutKeyPress)
            } else {
              monitor.eventPublisher.send(.commonKeyPress)
            }
          }

          return Unmanaged.passRetained(event)
        },
        userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
      )
    else {
      fatalError("Failed to create key event tap")
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
