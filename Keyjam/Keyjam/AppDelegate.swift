import AVFoundation
import AppKit
import Combine
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
  var streakTracker: StreakTracker?
  var mouseBreakAudio: AVAudioPlayer?
  var subscriptions: Set<AnyCancellable> = []

  func applicationDidFinishLaunching(_ notification: Notification) {
    if !ProcessInfo.processInfo.isExecutingInXcodeSwiftUIPreview {
      preloadAudio()
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

  @MainActor
  private func initializeStreakTracker() {
    let streakTracker = StreakTracker(repository: StreakRepository.shared)
    streakTracker.streakOutEventPublisher
      .receive(on: DispatchQueue.main)
      .sink { _ in
      } receiveValue: { event in
        switch event {
        case .decreased, .increased, .reset:
          break
        case .mouseBrokeStreak(let keyCount):
          if keyCount > 15 {
            Task {
              self.mouseBreakAudio?.volume = 0.1
              self.mouseBreakAudio?.play()
            }
          }
        }
      }
      .store(in: &subscriptions)

    streakTracker.context = .apps(named: ["Xcode", "Terminal", "Ghostty", "Visual Studio Code"])
    self.streakTracker = streakTracker
  }
}

extension ProcessInfo {
  var isExecutingInXcodeSwiftUIPreview: Bool {
    environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
  }
}
