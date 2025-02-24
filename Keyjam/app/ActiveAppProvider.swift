import CoreGraphics
import Foundation

protocol ActiveAppProvider {
  func getForegroundAppName() -> String?
}

class WindowSystemAppProvider: ActiveAppProvider {
  func getForegroundAppName() -> String? {
    var activeAppName: String?

    let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .optionIncludingWindow)

    guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as NSArray? else {
      return nil
    }

    for entry in windowList {
      if let window = entry as? NSDictionary,
        let isOnScreen = window[kCGWindowIsOnscreen] as? Bool,
        let layer = window[kCGWindowLayer] as? Int,
        let ownerName = window[kCGWindowOwnerName] as? String,
        isOnScreen && layer == 0
      {  // Filter for foreground, user-facing window
        activeAppName = ownerName  // Return the app name
        break
      }
    }

    return activeAppName
  }
}
