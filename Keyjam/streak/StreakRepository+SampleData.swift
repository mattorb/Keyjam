import Foundation

extension StreakRepository {
  func loadSampleMonth() {
    #if DEBUG
      if shouldLoad() {
        let sampleEvents = StreakRepository.generateMonthOfDataWithUpwardTrend()
        FileManager.saveStreakEvents(sampleEvents)
        loadStreakEvents()
      }
    #endif
  }

  private func shouldLoad() -> Bool {
    let xpcServiceName = ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"] ?? ""
    let isXcodeLaunch = xpcServiceName.contains("Xcode") || xpcServiceName.contains("com.apple.dt")
    let hasCustomFlag = ProcessInfo.processInfo.environment["RESET_TO_SAMPLE_DATA"] == "YES"

    return isXcodeLaunch || hasCustomFlag
  }

  static func generateMonthOfDataWithUpwardTrend() -> [StreakEvent] {
    let calendar = Calendar.current
    let now = Date()
    var events: [StreakEvent] = []

    let startValue = 8  // Starting streak count
    let endValue = 65  // Ending streak count

    let dayCount = 30
    let valueIncrease = Double(endValue - startValue) / Double(dayCount - 1)

    for day in 0..<dayCount {
      let eventsPerDay = Int.random(in: 1...3)

      for _ in 0..<eventsPerDay {
        let dayOffset = dayCount - 1 - day

        let baseValue = Double(startValue) + (valueIncrease * Double(day))

        let maxVariation = max(2.0, baseValue * 0.15)
        let randomVariation = Double.random(in: -maxVariation...maxVariation)

        let streakCount = max(4, Int(baseValue + randomVariation))

        let hourOffset = Int.random(in: 9...17)  // Business hours
        if let eventDate = calendar.date(byAdding: .day, value: -dayOffset, to: now),
          let timestamp = calendar.date(bySettingHour: hourOffset, minute: Int.random(in: 0...59), second: 0, of: eventDate)
        {

          events.append(StreakEvent(timestamp: timestamp, streakCount: streakCount))
        }
      }
    }

    return events.sorted { $0.timestamp < $1.timestamp }
  }

  static func createSampleData(
    startValue: Int,
    endValue: Int,
    count: Int,
    now: Date,
    calendar: Calendar
  ) -> [StreakEvent] {
    var sampleData: [StreakEvent] = []

    let step = Double(endValue - startValue) / Double(count - 1)

    for i in 0..<count {
      if let timestamp = calendar.date(byAdding: .hour, value: -i, to: now) {
        let trendValue = Double(startValue) + (step * Double(i))
        let randomVariation = Double.random(in: -3...3)
        let streak = max(4, Int(trendValue + randomVariation))

        sampleData.append(StreakEvent(timestamp: timestamp, streakCount: streak))
      }
    }

    return sampleData.sorted { $0.timestamp < $1.timestamp }
  }
}
