import AVFoundation
import AppKit
import Combine
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
  var mouseBreakAudio: AVAudioPlayer?
  var subscriptions: Set<AnyCancellable> = []

  func applicationDidFinishLaunching(_ notification: Notification) {
    if !ProcessInfo.processInfo.isExecutingInXcodeSwiftUIPreview {
      preloadAudio()

      guard let repository = DependencyContainer.shared.resolve(type: StreakRepository.self) else {
        return
      }

      repository.loadSampleMonth()

      initializeStreakTracker()
    }
  }

  private func preloadAudio() {
    if let soundURL = Bundle.main.url(forResource: "mousebreak", withExtension: "mp3") {
      do {
        mouseBreakAudio = try AVAudioPlayer(contentsOf: soundURL)
      } catch {
        print("audio player init error: \(error)")
      }
    }
  }

  private func initializeStreakTracker() {
    guard let coordinator = DependencyContainer.shared.resolve(type: StreakCoordinator.self) else {
      fatalError("Error initializing")
    }

    coordinator.start()

    coordinator.streakOutEventPublisher
      .receive(on: DispatchQueue.main)
      .sink { _ in
      } receiveValue: { event in
        switch event {
        case .decreased, .increased, .reset:
          break
        case .mouseBrokeStreak(let keyCount):
          if keyCount > 15,
            !UserDefaults.standard.bool(forKey: Settings.disableStreakBrokenSound)
          {
            self.mouseBreakAudio?.volume = 0.1
            self.mouseBreakAudio?.play()
          }
        }
      }
      .store(in: &subscriptions)
  }
}

extension ProcessInfo {
  var isExecutingInXcodeSwiftUIPreview: Bool {
    environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
  }
}
