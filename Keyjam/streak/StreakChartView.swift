import Charts
import SwiftUI

// MARK: - Main View
struct StreakChartView: View {
  let streakEvents: [StreakEvent]
  @Binding var timeScope: StreakChartTimeScope
  @State private var selectedEvent: StreakEvent?
  @State private var hoverLocation: CGPoint?
  @State private var chartSize: CGSize = .zero

  var body: some View {
    VStack(alignment: .leading) {
      headerView

      if streakEvents.isEmpty {
        emptyStateView
      } else {
        simpleChartView
      }
    }
  }

  // MARK: - Subviews
  private var headerView: some View {
    HStack {
      Text("Recent Streak Events")
        .font(.caption)
        .foregroundColor(.secondary)

      Spacer()

      if !streakEvents.isEmpty {
        Picker("", selection: $timeScope) {
          ForEach(StreakChartTimeScope.allCases) { scope in
            Text(scope.rawValue).tag(scope)
          }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .frame(width: 70)
        .controlSize(.small)
      }
    }
  }

  private var emptyStateView: some View {
    Text("No streak data available yet")
      .font(.caption)
      .foregroundColor(.secondary)
      .frame(height: 100)
  }

  private var simpleChartView: some View {
    VStack {
      Chart {
        ChartDataPointsView(streakEvents: streakEvents)

        if streakEvents.count >= 2, let trendLineData = calculateTrendLine() {
          TrendLineView(startPoint: trendLineData.0, endPoint: trendLineData.1)
        }

        if let selectedEvent = selectedEvent {
          RuleMark(
            x: .value("Selected", selectedEvent.timestamp)
          )
          .foregroundStyle(Color.teal.opacity(0.3))
          .lineStyle(StrokeStyle(lineWidth: 1))
        }

        SelectedPointAnnotationView(
          streakEvents: streakEvents,
          selectedEvent: selectedEvent,
          getAnnotationPosition: getAnnotationPosition
        )
      }
      .chartYScale(domain: 0...yAxisUpperBound)
      .chartXAxis {
        configureChartAxis(dataSpansLessThanOneDay: dataSpansLessThanOneDay)
      }
      .chartYAxis {
        AxisMarks(position: .leading)
      }
      .frame(height: 160)
      .background(
        GeometryReader { geometry in
          Color.clear
            .onAppear {
              chartSize = geometry.size
            }
            .onChange(of: geometry.size) {
              chartSize = geometry.size
            }
        }
      )
      .chartOverlay { proxy in
        ChartOverlayInteraction(
          proxy: proxy,
          streakEvents: streakEvents,
          selectedEvent: $selectedEvent,
          hoverLocation: $hoverLocation
        )
      }
    }
  }

  // MARK: - Helper Methods
  private func getAnnotationPosition(for event: StreakEvent) -> AnnotationPosition? {
    guard !streakEvents.isEmpty else { return .top }

    let sortedEvents = streakEvents.sorted { $0.timestamp < $1.timestamp }
    guard sortedEvents.first != nil,
      sortedEvents.last != nil,
      let index = sortedEvents.firstIndex(where: { $0.id == event.id })
    else {
      return .top
    }

    let totalEvents = sortedEvents.count
    let relativePosition = Double(index) / Double(totalEvents - 1)

    if relativePosition < 0.2 {
      return .trailing  // For points near the left edge
    } else if relativePosition > 0.8 {
      return .leading  // For points near the right edge
    } else if Double(event.streakCount) > Double(maxStreakCount) * 0.8 {
      return .bottom  // For points near the top
    } else if Double(event.streakCount) < Double(maxStreakCount) * 0.2 {
      return .top  // For points near the bottom
    } else {
      return .top  // Default position
    }
  }

  private func calculateTrendLine() -> ((timestamp: Date, value: Double), (timestamp: Date, value: Double))? {
    guard streakEvents.count >= 2 else { return nil }

    let timestamps = streakEvents.map { $0.timestamp.timeIntervalSince1970 }
    let counts = streakEvents.map { Double($0.streakCount) }

    let meanX = timestamps.reduce(0, +) / Double(timestamps.count)
    let meanY = counts.reduce(0, +) / Double(counts.count)

    var numerator: Double = 0
    var denominator: Double = 0

    for i in 0..<timestamps.count {
      numerator += (timestamps[i] - meanX) * (counts[i] - meanY)
      denominator += pow(timestamps[i] - meanX, 2)
    }

    guard denominator != 0 else { return nil }

    let slope = numerator / denominator
    let intercept = meanY - slope * meanX

    let startTimestamp = streakEvents.first!.timestamp
    let endTimestamp = streakEvents.last!.timestamp

    let startValue = slope * startTimestamp.timeIntervalSince1970 + intercept
    let endValue = slope * endTimestamp.timeIntervalSince1970 + intercept

    return ((startTimestamp, startValue), (endTimestamp, endValue))
  }

  private func configureChartAxis(dataSpansLessThanOneDay: Bool) -> some AxisContent {
    switch timeScope {
    case .day:
      return AxisMarks(preset: .aligned, values: .stride(by: .hour, count: 3)) {
        AxisGridLine()
        AxisTick()
        AxisValueLabel(format: .dateTime.hour(), anchor: .top)
      }
    case .week:
      return AxisMarks(preset: .aligned, values: .stride(by: .day)) {
        AxisGridLine()
        AxisTick()
        AxisValueLabel(format: .dateTime.weekday(.abbreviated), anchor: .top)
      }
    case .month:
      return AxisMarks(preset: .aligned, values: .stride(by: .day, count: 3)) {
        AxisGridLine()
        AxisTick()
        AxisValueLabel(format: .dateTime.month(.defaultDigits).day(), anchor: .top)
      }
    }
  }

  // MARK: - Computed Properties
  private var maxStreakCount: Int {
    streakEvents.map { $0.streakCount }.max() ?? 0
  }

  private var yAxisUpperBound: Int {
    max(maxStreakCount + 5, 20)
  }

  private var dataSpansLessThanOneDay: Bool {
    guard streakEvents.count > 1 else { return true }

    let sortedEvents = streakEvents.sorted { $0.timestamp < $1.timestamp }
    guard let earliest = sortedEvents.first?.timestamp,
      let latest = sortedEvents.last?.timestamp
    else {
      return true
    }

    let timeSpan = latest.timeIntervalSince(earliest)
    let hoursSpan = timeSpan / 3600

    return hoursSpan < 24
  }
}

// MARK: - Chart Components
struct ChartDataPointsView: ChartContent {
  let streakEvents: [StreakEvent]

  var body: some ChartContent {
    ForEach(streakEvents) { event in
      let size = min(30, max(15, event.streakCount / 2))

      PointMark(
        x: .value("Time", event.timestamp),
        y: .value("Streak", event.streakCount)
      )
      .foregroundStyle(Color.teal.gradient)
      .symbolSize(CGFloat(size))
      .accessibilityLabel("\(event.streakCount) keystrokes at \(FormatterProvider.dateTimeFormatter.string(from: event.timestamp))")
    }
  }
}

struct TrendLineView: ChartContent {
  let startPoint: (timestamp: Date, value: Double)
  let endPoint: (timestamp: Date, value: Double)

  private var trendDirection: TrendDirection {
    endPoint.value > startPoint.value ? .up : (endPoint.value < startPoint.value ? .down : .flat)
  }

  private var trendColor: Color {
    trendDirection == .up ? Color.green : (trendDirection == .down ? Color.red : Color.orange)
  }

  var body: some ChartContent {
    LineMark(
      x: .value("Start Time", startPoint.timestamp),
      y: .value("Start Value", startPoint.value)
    )
    .foregroundStyle(trendColor)
    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

    LineMark(
      x: .value("End Time", endPoint.timestamp),
      y: .value("End Value", endPoint.value)
    )
    .foregroundStyle(trendColor)
    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))

    PointMark(
      x: .value("End Time", endPoint.timestamp),
      y: .value("End Value", endPoint.value)
    )
    .foregroundStyle(.clear)
  }
}

struct SelectedPointAnnotationView: ChartContent {
  let streakEvents: [StreakEvent]
  let selectedEvent: StreakEvent?
  let getAnnotationPosition: (StreakEvent) -> AnnotationPosition?

  var body: some ChartContent {
    ForEach(streakEvents) { event in
      if selectedEvent?.id == event.id, let position = getAnnotationPosition(event) {
        PointMark(
          x: .value("Selected Time", event.timestamp),
          y: .value("Selected Value", event.streakCount)
        )
        .foregroundStyle(Color.teal)
        .symbolSize(CGFloat(min(40, max(20, event.streakCount / 2))))
        .annotation(position: position) {
          TooltipView(event: event)
        }
      }
    }
  }
}

struct ChartOverlayInteraction: View {
  let proxy: ChartProxy
  let streakEvents: [StreakEvent]
  @Binding var selectedEvent: StreakEvent?
  @Binding var hoverLocation: CGPoint?

  var body: some View {
    GeometryReader { geometry in
      Rectangle()
        .fill(Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovering in
          if !isHovering {
            selectedEvent = nil
            hoverLocation = nil
          }
        }
        .onContinuousHover { phase in
          switch phase {
          case .active(let location):
            hoverLocation = location
            updateSelectedEvent(at: location)

          case .ended:
            selectedEvent = nil
            hoverLocation = nil
          }
        }
    }
  }

  private func updateSelectedEvent(at location: CGPoint) {
    let eventsWithPositions = streakEvents.compactMap { event -> (event: StreakEvent, position: CGPoint)? in
      guard let position = proxy.position(for: (x: event.timestamp, y: event.streakCount)) else {
        return nil
      }
      return (event, position)
    }

    let horizontallyAlignedEvents = eventsWithPositions.filter {
      abs(location.x - $0.position.x) <= 10
    }

    if !horizontallyAlignedEvents.isEmpty {
      let closestEvent = horizontallyAlignedEvents.min(by: {
        abs(location.x - $0.position.x) < abs(location.x - $1.position.x)
      })?.event

      if let event = closestEvent {
        selectedEvent = event
      } else {
        selectedEvent = nil
      }
    } else {
      if let closestByX = eventsWithPositions.min(by: {
        abs(location.x - $0.position.x) < abs(location.x - $1.position.x)
      }) {
        if abs(location.x - closestByX.position.x) <= 30 {
          selectedEvent = closestByX.event
        } else {
          selectedEvent = nil
        }
      } else {
        selectedEvent = nil
      }
    }
  }
}

struct TooltipView: View {
  let event: StreakEvent

  var body: some View {
    VStack(alignment: .center, spacing: 4) {
      Text("\(event.streakCount)")
        .font(.system(size: 18, weight: .bold))
        .foregroundColor(Color.teal)

      Text(FormatterProvider.hoverDateFormatter.string(from: event.timestamp))
        .font(.system(size: 12))
        .foregroundColor(.secondary)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(NSColor.windowBackgroundColor))
        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.teal.opacity(0.3), lineWidth: 1)
        )
    )
  }
}

// MARK: - Utilities
enum FormatterProvider {
  static var dateTimeFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, HH:mm"
    return formatter
  }

  static var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter
  }

  static var hoverDateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
  }
}

enum TrendDirection {
  case up, down, flat
}

// MARK: - Preview
#Preview(traits: .sizeThatFitsLayout) {
  VStack(spacing: 20) {
    Text("Download Trend over day")
      .font(.headline)
    StreakChartView(
      streakEvents: StreakRepository.createSampleData(startValue: 10, endValue: 50, count: 10, now: Date(), calendar: Calendar.current),
      timeScope: .constant(.day)
    )
    .padding()
    .background(Color.primary.opacity(0.1))
    .cornerRadius(8)
    .shadow(radius: 2)

    Text("Upward Trend over week")
      .font(.headline)
    StreakChartView(
      streakEvents: StreakRepository.createSampleData(startValue: 50, endValue: 10, count: 10, now: Date(), calendar: Calendar.current),
      timeScope: .constant(.day)
    )
    .padding()
    .background(Color.primary.opacity(0.1))
    .cornerRadius(8)
    .shadow(radius: 2)

    Text("Busy Month")
      .font(.headline)
    StreakChartView(
      streakEvents: StreakRepository.generateMonthOfDataWithUpwardTrend(),
      timeScope: .constant(.month)
    )
    .padding()
    .background(Color.primary.opacity(0.1))
    .cornerRadius(8)
    .shadow(radius: 2)
  }
  .padding()
}

enum StreakChartTimeScope: String, CaseIterable, Identifiable {
  case day = "Day"
  case week = "Week"
  case month = "Month"

  var id: String { rawValue }
}
