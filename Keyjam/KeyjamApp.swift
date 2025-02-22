import SwiftUI

@main
struct KeyjamApp: App {
  let container = DependencyContainer.shared  // use the same one as app delegate.   see below.

  init() {
    initializeDependencies(container: container)
  }

  // Issue starting CGEvent tap's before app 'finishedLaunching', and menubar app never 'appears' like a view,
  //  so falling back to delegate method
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    KeyjamMenuBar()
      .environment(StreakRepository.self, from: container)
      .environment(StreakTracker.self, from: container)
  }
}
