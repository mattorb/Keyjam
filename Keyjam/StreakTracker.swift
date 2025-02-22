import AVFoundation
import Combine
import CoreGraphics
import Foundation

@Observable
class StreakTracker {
  enum InitializationState {
    case stopped
    case started
  }

  enum StreakContext {
    case all
    case apps(named: [String])
  }

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

  @ObservationIgnored
  let repository: StreakRepository

  @ObservationIgnored
  var context: StreakContext = .all

  @ObservationIgnored
  var mouseEventTap: CFMachPort?

  @ObservationIgnored
  var keyEventTap: CFMachPort?

  @ObservationIgnored
  let streakInEventPublisher = PassthroughSubject<StreakInEvent, Never>()

  @ObservationIgnored
  let streakOutEventPublisher = PassthroughSubject<StreakOutEvent, Never>()

  @ObservationIgnored
  var subscriptions: [AnyCancellable] = []

  var state: InitializationState = .stopped

  init(repository: StreakRepository) {
    self.repository = repository
  }

  func start() {
    setupMouseMovementTap()
    setupGlobalKeyTap()
    startListeningToEvents()
    state = .started
  }

  func startListeningToEvents() {
    streakInEventPublisher
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { value in
          var shouldCount = false

          switch self.context {
          case .all:
            shouldCount = true
          case .apps(let appNames):
            let foregroundAppName = self.getForegroundAppName()
            if appNames.contains(where: {
              foregroundAppName == $0
            }) {
              shouldCount = true
            }
          }

          if shouldCount {
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
        }
      )
      .store(in: &subscriptions)
  }

  func updateContext(appNames: [String]) {
    self.context = appNames.isEmpty ? .all : .apps(named: appNames)
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
      fatalError("Failed to create mouse event tap")
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

  private func getForegroundAppName() -> String? {
    var activeAppName: String?

    let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .optionIncludingWindow)

    // Retrieve the window list
    guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as NSArray? else {
      return nil
    }

    for entry in windowList {
      if let window = entry as? NSDictionary,
        let isOnScreen = window[kCGWindowIsOnscreen] as? Bool,
        let layer = window[kCGWindowLayer] as? Int,
        let ownerName = window[kCGWindowOwnerName] as? String,
        isOnScreen && layer == 0
      {  // Filter for foreground, user-facing window
        activeAppName = ownerName  // Return the app name
        break
      }
    }

    return activeAppName
  }
}
