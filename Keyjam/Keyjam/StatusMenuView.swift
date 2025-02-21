import ServiceManagement
import SwiftUI

struct StatusMenuView: View {
  @State private var launchAtLogin = false
  
  var body: some View {
    VStack {
      Text("Status Menu View")
      
      Divider()
      
      Section("Settings") {
        Toggle("Launch Make me Stand at Login (toggle)", isOn: $launchAtLogin)
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
    }
    .padding()
  }
}
