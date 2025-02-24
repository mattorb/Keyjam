import Foundation
import SwiftUI

// Enable storing a [String] via @AppStorage
extension Array: @retroactive RawRepresentable where Element: Codable {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
      let result = try? JSONDecoder().decode([Element].self, from: data)
    else {
      return nil
    }
    self = result
  }

  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
      let result = String(data: data, encoding: .utf8)
    else {
      return "[]"
    }
    return result
  }
}

// Enable retrieving it directly from UserDefaults (outside Views)
extension UserDefaults {
  func decodedStringArray(forKey key: String) -> [String]? {
    guard let jsonString = string(forKey: key),
      let jsonData = jsonString.data(using: .utf8)
    else {
      return nil
    }

    do {
      let decodedArray = try JSONDecoder().decode([String].self, from: jsonData)
      return decodedArray
    } catch {
      print("Error decoding JSON for key \(key): \(error)")
      return nil
    }
  }
}
