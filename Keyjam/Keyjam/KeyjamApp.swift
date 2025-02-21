import SwiftUI

@main
struct KeyjamApp: App {
  var body: some Scene {
    MenuBarExtra {
      StatusMenuView()
    } label: {
      Text("⌨️")
    }
    .menuBarExtraStyle(.window)
  }
}
