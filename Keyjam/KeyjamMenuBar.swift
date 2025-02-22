import Observation
import ServiceManagement
import SwiftUI

struct KeyjamMenuBar: Scene {
  @Environment(StreakRepository.self) var keyCount
  @Environment(StreakTracker.self) var streakTracker

  @State private var launchAtLogin = false
  @State private var newAppName: String = ""
  @AppStorage("trackedApps") private var trackedApps: [String] = []

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
        Text("KeyJam")
          .font(.headline)

        Text(streakTracker.state == .started ? "Initialized successfully." : "Issue initializing.  Check permissions & relaunch.")
          .font(.caption)

        Spacer()

        Text("Statistics")
          .font(.headline)

        Text("Current key streak: \(keyCount.keyCount)")

        Spacer()

        Text("Usage")
          .font(.headline)

        if case .all = streakTracker.context {
          Text("Currently counting all sequential keystrokes from all applications.  Using the mouse will reset the streak.")
        } else {
          Text(
            "Currently counting sequential keystrokes from selected applications.  Using the mouse while one of those apps is selected will reset the streak."
          )
        }

        Spacer()

        Text("Applications Filter")
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
            }
          }
        }

        HStack {
          TextField(
            "Add application named...", text: $newAppName,
            onCommit: {
              addApp()
            })

          Button("Add") {
            addApp()
          }
          .disabled(newAppName.isEmpty)
        }

        Spacer()

        Text("More Options")
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

        Spacer()

        HStack {
          Text("KeyJam version \(appVersion)")
          Spacer()
          Button("Quit") {
            NSApplication.shared.terminate(nil)
          }.keyboardShortcut("q")
            .padding()
        }
      }
      .padding()
    } label: {
      Text("⌨️ \(keyCount.keyCount)")
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
