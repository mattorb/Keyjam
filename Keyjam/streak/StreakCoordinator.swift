import AVFoundation
import Combine
import CoreGraphics
import Foundation
import Observation

@Observable
final class StreakCoordinator {
  enum InitializationState {
    case stopped
    case started
  }

  @ObservationIgnored
  private let repository: StreakRepository

  @ObservationIgnored
  private let engine: StreakEngine

  @ObservationIgnored
  let streakOutEventPublisher = PassthroughSubject<StreakOutEvent, Never>()

  @ObservationIgnored
  private let keyboardMonitor: InputMonitor

  @ObservationIgnored
  private let mouseMonitor: InputMonitor

  @ObservationIgnored
  private let appProvider: ActiveAppProvider

  @ObservationIgnored
  private var subscriptions: [AnyCancellable] = []

  private var context: StreakContext = .all

  var state: InitializationState = .stopped

  var isEnabled: Bool = true {
    didSet {
      if isEnabled {
        start()
      } else {
        stop()
      }
    }
  }

  init(
    repository: StreakRepository, keyboardMonitor: InputMonitor = KeyboardMonitor(), mouseMonitor: InputMonitor = MouseMonitor(),
    appProvider: ActiveAppProvider = WindowSystemAppProvider()
  ) {
    self.repository = repository
    self.appProvider = appProvider
    self.engine = StreakEngine(repository: repository)
    self.keyboardMonitor = keyboardMonitor
    self.mouseMonitor = mouseMonitor
  }

  private func setupSubscriptions() {
    keyboardMonitor.eventPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] event in
        self?.handleInput(event)
      }
      .store(in: &subscriptions)

    mouseMonitor.eventPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] event in
        self?.handleInput(event)
      }
      .store(in: &subscriptions)
  }

  private func handleInput(_ event: StreakInEvent) {
    // Only process events if they occur in tracked apps
    guard shouldCountForCurrentContext() else {
      return
    }

    var outEvent: StreakOutEvent?

    switch event {
    case .commonKeyPress, .shortcutKeyPress:
      outEvent = engine.processKeyPress()
    case .mouseMoveStarted:
      outEvent = engine.processMouseMove()
    }

    if let event = outEvent {
      streakOutEventPublisher.send(event)
      if case .mouseBrokeStreak = event {
        streakOutEventPublisher.send(.reset)
      }
    }
  }

  private func shouldCountForCurrentContext() -> Bool {
    switch context {
    case .all:
      return true
    case .apps(let appNames):
      if let foregroundAppName = appProvider.getForegroundAppName() {
        return appNames.contains(foregroundAppName)
      }
      return false
    }
  }

  func start() {
    if let apps = UserDefaults.standard.decodedStringArray(forKey: Settings.trackedApps) {
      updateContext(appNames: apps)
    }

    setupSubscriptions()

    let keyMonitorStarted = keyboardMonitor.start()
    let mouseMonitorStarted = mouseMonitor.start()

    if keyMonitorStarted && mouseMonitorStarted {
      state = .started
    } else {
      stop()
    }
  }

  func stop() {
    keyboardMonitor.stop()
    mouseMonitor.stop()
  }

  func updateContext(appNames: [String]) {
    self.context = appNames.isEmpty ? .all : .apps(named: appNames)
  }
}
