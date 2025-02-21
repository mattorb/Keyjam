import ServiceManagement
import SwiftUI

struct StatusMenuView: View {
  @State private var launchAtLogin = false
  @State private var showPointsInStatusMenu = false

  var keyCount: StreakRepository

  var body: some View {
    VStack {
      Spacer()
      Text("KeyJam")
        .font(.title)
      Spacer()
      Divider()

      VStack(alignment: .center) {
        Section("Stats") {
          Text("Current Keyboard streak: \(keyCount.keyCount)")
          Text("Mouse breaks: \(keyCount.mouseBreak)")
        }

        Spacer()

        Section("Settings") {
          Toggle("Launch Make me Stand at Login", isOn: $launchAtLogin)
            .onChange(of: launchAtLogin) { previousValue, newValue in
              if newValue, !previousValue {
                do {
                  try SMAppService.mainApp.register()
                  print("Registered for Launch at Login")
                } catch {
                  print("Failed to register: \(error)")
                }
              } else {
                do {
                  try SMAppService.mainApp.unregister()
                } catch {
                  print("Failed to deregister: \(error)")
                }
                print("Unregistered from Launch at Login")
              }
            }
            .onAppear {
              launchAtLogin = (SMAppService.mainApp.status == .enabled)
            }
        }

        Divider()

        Button("Quit") {
          NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
      }
      .padding()
    }
  }
}
