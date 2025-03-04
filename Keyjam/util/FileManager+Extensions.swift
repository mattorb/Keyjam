import Foundation

extension FileManager {

  /// Returns the URL for the application support directory
  static func getAppSupportDirectory() -> URL {
    let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    let appSupportDirectory = paths[0].appendingPathComponent("Keyjam", isDirectory: true)

    // Create directory if it doesn't exist
    if !FileManager.default.fileExists(atPath: appSupportDirectory.path) {
      try? FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)
    }

    return appSupportDirectory
  }

  /// Returns the URL for the streak events JSON file
  static func getStreakEventsFileURL() -> URL {
    return getAppSupportDirectory().appendingPathComponent("streak_events.json")
  }

  /// Saves streak events to a JSON file
  static func saveStreakEvents(_ events: [StreakEvent]) {
    let fileURL = getStreakEventsFileURL()

    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let data = try encoder.encode(events)
      try data.write(to: fileURL)
    } catch {
      print("Error saving streak events: \(error)")
    }
  }

  /// Loads streak events from a JSON file
  static func loadStreakEvents() -> [StreakEvent] {
    let fileURL = getStreakEventsFileURL()

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return []
    }

    do {
      let data = try Data(contentsOf: fileURL)
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode([StreakEvent].self, from: data)
    } catch {
      print("Error loading streak events: \(error)")
      return []
    }
  }
}
