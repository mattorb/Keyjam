import SwiftUI

@main
struct KeyjamApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @State var keyCount: StreakRepository = .shared

  var body: some Scene {
    MenuBarExtra {
      StatusMenuView(keyCount: keyCount)
    } label: {
      Text("⌨️ \(keyCount.keyCount)")
    }
    .menuBarExtraStyle(.window)
  }
}
