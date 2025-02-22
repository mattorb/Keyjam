import Observation
import ServiceManagement
import SwiftUI

struct KeyjamMenuBar: Scene {
  @Environment(StreakRepository.self) var keyCount
  @Environment(StreakTracker.self) var streakTracker

  @State private var launchAtLogin = false
  @State private var newAppName: String = ""
  @AppStorage("trackedApps") private var trackedApps: [String] = []

  enum Layout {
    public static let verticalSpacer: CGFloat = 20.0
  }

  var appVersion: String {
    guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
      let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    else {
      return "Unknown"
    }

    return "\(version)-\(build)"
  }

  var body: some Scene {
    MenuBarExtra {
      VStack(alignment: .leading) {
        Text("Statistics")
          .font(.headline)

        Text("Current key streak: \(keyCount.keyCount)")

        Spacer(minLength: Layout.verticalSpacer)

        Text("Usage")
          .font(.headline)

        Text("Currently counting sequential keystrokes.  Using mouse will reset streak, and if >15 streak play a sad sound.")

        Spacer(minLength: Layout.verticalSpacer)

        Text("Applications include filter")
          .font(.headline)

        if !trackedApps.isEmpty {
          ForEach(trackedApps, id: \.self) { app in
            HStack {
              Text(app)
              Spacer()
              Button(action: {
                trackedApps.removeAll { $0 == app }
                streakTracker.updateContext(appNames: trackedApps)
              }) {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.red)
              }
              .buttonStyle(.plain)
            }
          }
        }

        HStack {
          TextField(
            "Add application named...", text: $newAppName,
            onCommit: {
              addApp()
            })

          Button(action: {
            addApp()
          }) {
            Image(systemName: "plus.circle.fill")
              .foregroundColor(.green)
          }
          .buttonStyle(.plain)
          .disabled(newAppName.isEmpty)
        }

        Spacer(minLength: Layout.verticalSpacer)

        Text("Options")
          .font(.headline)

        Toggle("Launch automatically at login", isOn: $launchAtLogin)
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

        Spacer(minLength: Layout.verticalSpacer)

        HStack {
          VStack {
            Text("Keyjam version \(appVersion)")
              .font(.headline)
          }
          Spacer()
          Button("Quit") {
            NSApplication.shared.terminate(nil)
          }.keyboardShortcut("q")
            .padding()
        }

      }
      .padding()
    } label: {
      Image(systemName: "keyboard")
      Text("\(keyCount.keyCount)")
    }
    .menuBarExtraStyle(.window)
  }

  private func addApp() {
    if !newAppName.isEmpty && !trackedApps.contains(newAppName) {
      trackedApps.append(newAppName)
      streakTracker.updateContext(appNames: trackedApps)
      newAppName = ""
    }
  }
}
