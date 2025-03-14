import Observation
import ServiceManagement
import SwiftUI

struct KeyjamMenuBar: Scene {
  @Environment(StreakRepository.self) var keyCount
  @Environment(StreakCoordinator.self) var coordinator

  @State private var selectedTimeScope: StreakChartTimeScope = .day
  @State private var launchAtLogin = false
  @State private var newAppName: String = ""
  @State private var hasInputPermission: Bool = false
  @AppStorage(Settings.trackedApps) private var trackedApps: [String] = []
  @AppStorage(Settings.disableStreakBrokenSound) private var disableStreakBrokenSound: Bool = false

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

  private var recentStreakEvents: [StreakEvent] {
    // Convert TimeScope to days for the repository method
    let days: Int
    switch selectedTimeScope {
    case .day:
      days = 1
    case .week:
      days = 7
    case .month:
      days = 30
    }

    return keyCount.getRecentStreakEvents(days: days)
  }

  private var streakStats: String {
    let events = recentStreakEvents
    guard !events.isEmpty else { return "No recent streaks" }

    let count = events.count
    let avgStreak = events.reduce(0) { $0 + $1.streakCount } / count

    return "\(count) streaks, avg: \(avgStreak)"
  }

  var body: some Scene {
    MenuBarExtra {
      VStack(alignment: .leading) {
        statisticsSection

        Spacer(minLength: Layout.verticalSpacer)

        usageSection

        Spacer(minLength: Layout.verticalSpacer)

        applicationsSection

        Spacer(minLength: Layout.verticalSpacer)

        permissionSection

        Spacer(minLength: Layout.verticalSpacer)

        optionsSection

        Spacer(minLength: Layout.verticalSpacer)

        dataSection

        Spacer(minLength: Layout.verticalSpacer)

        footerSection
      }
      .padding()
      .onAppear {
        hasInputPermission = CGPreflightListenEventAccess()
      }
    } label: {
      menuBarLabel
    }
    .menuBarExtraStyle(.window)
  }

  // MARK: - Menu Bar Sections

  private var statisticsSection: some View {
    VStack(alignment: .leading) {
      Text("Statistics")
        .font(.headline)

      HStack {
        Text("Current key streak: \(keyCount.keyCount)")
        Spacer()
        if !recentStreakEvents.isEmpty {
          Text("Highest: \(recentStreakEvents.map { $0.streakCount }.max() ?? 0)")
            .foregroundColor(Color.teal)
        }
      }

      Text(streakStats)
        .font(.caption)
        .foregroundColor(.secondary)

      StreakChartView(streakEvents: recentStreakEvents, timeScope: $selectedTimeScope)
        .padding(.vertical, 5)
    }
  }

  private var usageSection: some View {
    VStack(alignment: .leading) {
      Text("Usage")
        .font(.headline)
      Text("Currently counting sequential keystrokes. Using mouse will reset streak, and if >15 streak play a sad sound.")
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)  // MenuBarExtra doesn't support multiline text issue
    }
  }

  private var applicationsSection: some View {
    VStack(alignment: .leading) {
      Text("Applications include filter")
        .font(.headline)

      if !trackedApps.isEmpty {
        ForEach(trackedApps, id: \.self) { app in
          appRow(for: app)
        }
      }

      addAppRow
    }
  }

  private func appRow(for app: String) -> some View {
    HStack {
      Text(app)
      Spacer()
      Button(action: {
        trackedApps.removeAll { $0 == app }
        coordinator.updateContext(appNames: trackedApps)
      }) {
        Image(systemName: "xmark.circle.fill")
          .foregroundColor(.red)
      }
      .buttonStyle(.plain)
    }
  }

  private var addAppRow: some View {
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
  }

  private let accessibilityPermissionURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!

  private var permissionSection: some View {
    VStack(alignment: .leading) {
      Text("Permissions")
        .font(.headline)

      if !hasInputPermission {
        HStack {
          Image(systemName: "exclamationmark.circle.fill")
            .foregroundColor(.red)
          Text("Needs permission")
          Spacer()
          Button("Open Settings") {
            NSWorkspace.shared.open(accessibilityPermissionURL)
          }
          .buttonStyle(.link)
        }
        .padding(.bottom, 4)
        Text("Relaunch after granting permission")
      } else {
        HStack {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
          Text("System permission granted")
          Button("here") {
            NSWorkspace.shared.open(accessibilityPermissionURL)
          }
          .buttonStyle(.link)
          Spacer()
        }
        .padding(.bottom, 4)
      }
    }
  }

  private var optionsSection: some View {
    VStack(alignment: .leading) {
      Text("Options")
        .font(.headline)

      if hasInputPermission {
        keyCountingToggle
      }

      Toggle("Disable streak broken sound", isOn: $disableStreakBrokenSound)

      launchAtLoginToggle
    }
  }

  private var dataSection: some View {
    VStack(alignment: .leading) {
      Text("Data")
        .font(.headline)

      HStack {
        Button("Clear streak history", role: .destructive) {
          keyCount.clearAllData()
        }
        Spacer()
      }
    }
  }

  private var keyCountingToggle: some View {
    Toggle(
      "Key counting enabled",
      isOn: .init(
        get: { coordinator.isEnabled },
        set: { coordinator.isEnabled = $0 }
      ))
  }

  private var launchAtLoginToggle: some View {
    Toggle("Launch automatically at login", isOn: $launchAtLogin)
      .onChange(of: launchAtLogin) { previousValue, newValue in
        handleLaunchAtLoginChange(from: previousValue, to: newValue)
      }
      .onAppear {
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
      }
  }

  private func handleLaunchAtLoginChange(from previousValue: Bool, to newValue: Bool) {
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

  private var footerSection: some View {
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

  private var menuBarLabel: some View {
    HStack {
      Image(systemName: "keyboard")
      Text("\(keyCount.keyCount)")
    }
  }

  private func addApp() {
    if !newAppName.isEmpty && !trackedApps.contains(newAppName) {
      trackedApps.append(newAppName)
      coordinator.updateContext(appNames: trackedApps)
      newAppName = ""
    }
  }
}
