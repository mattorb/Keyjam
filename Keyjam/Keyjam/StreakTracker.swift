import AVFoundation
import Combine
import CoreGraphics
import Foundation

class StreakTracker {
  enum StreakInEvent {
    case commonKeyPress
    case shortcutKeyPress
    case mouseMoveStarted
  }

  enum StreakOutEvent {
    case reset
    case increased
    case decreased
    case mouseBrokeStreak(keyCount: Int)
  }

  let repository: StreakRepository
  var mouseEventTap: CFMachPort?
  var keyEventTap: CFMachPort?

  let streakInEventPublisher = PassthroughSubject<StreakInEvent, Never>()
  let streakOutEventPublisher = PassthroughSubject<StreakOutEvent, Never>()

  // Persistent subscription reference
  var subscriptions: [AnyCancellable] = []

  init(repository: StreakRepository) {
    self.repository = repository
    setupMouseMovementTap()
    setupGlobalKeyTap()
    startListeningToEvents()
  }

  func startListeningToEvents() {
    streakInEventPublisher
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { value in
          switch value {
          case .commonKeyPress, .shortcutKeyPress:
            self.repository.keyCount += 1
            self.streakOutEventPublisher.send(.increased)
            break
          case .mouseMoveStarted:
            if self.repository.keyCount > 0 {
              let keyCount = self.repository.keyCount
              self.repository.keyCount = 0
              self.repository.mouseBreak += 1
              self.streakOutEventPublisher.send(.mouseBrokeStreak(keyCount: keyCount))
              self.streakOutEventPublisher.send(.reset)
            }
          }
        }
      )
      .store(in: &subscriptions)
  }

  func setupMouseMovementTap() {
    let eventMask: CGEventMask =
      (1 << CGEventType.mouseMoved.rawValue) | (1 << CGEventType.leftMouseDragged.rawValue) | (1 << CGEventType.rightMouseDragged.rawValue)

    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: eventMask,
        callback: { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
          let tracker = Unmanaged<StreakTracker>.fromOpaque(userInfo!).takeUnretainedValue()

          if type == .mouseMoved || type == .leftMouseDragged || type == .rightMouseDragged {
            //let cursorPosition = event.location
            tracker.streakInEventPublisher.send(.mouseMoveStarted)
          }
          return Unmanaged.passUnretained(event)
        },
        userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
      )
    else {
      print("Failed to create mouse event tap")
      return
    }

    self.mouseEventTap = eventTap
    let runLoopSource = CFMachPortCreateRunLoopSource(
      kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(
      CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)

    CFRunLoopRun()  // Keep the run loop running
  }

  func setupGlobalKeyTap() {
    let eventMask = (1 << CGEventType.keyDown.rawValue)
    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask),
        callback: { proxy, type, event, userInfo in
          let tracker = Unmanaged<StreakTracker>.fromOpaque(userInfo!).takeUnretainedValue()

          if type == .keyDown {
            let flags = event.flags
            let shortcutMask: [CGEventFlags] = [.maskCommand, .maskControl, .maskAlternate, .maskHelp, .maskSecondaryFn]

            if !flags.intersection(CGEventFlags(shortcutMask)).isEmpty {
              tracker.streakInEventPublisher.send(.shortcutKeyPress)
            } else {
              tracker.streakInEventPublisher.send(.commonKeyPress)
            }
          }

          return Unmanaged.passRetained(event)
        },
        userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
      )
    else {
      fatalError("Failed to create key event tap")
    }

    self.keyEventTap = eventTap
    let runLoopSource = CFMachPortCreateRunLoopSource(
      kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(
      CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
  }
}
