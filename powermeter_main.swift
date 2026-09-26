import SwiftUI
import Foundation
import AppKit

@main
struct PowerMeterApp: App {
    @StateObject private var powerMonitor = PowerMonitor()

    var body: some Scene {
        MenuBarExtra {
            Text("Total System Power")
            Text("Today's Energy: \(powerMonitor.todayKWhStr)")
            Divider()
            Button("View Power Log (CSV)") {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/Users/Shared/power_history.csv"))
            }
            Divider()
            Button("Quit PowerMeter") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: "bolt.fill")
            Text("\(powerMonitor.currentKWStr) | \(powerMonitor.todayKWhStr)")
        }
    }
}

class PowerMonitor: ObservableObject {
    @Published var currentKWStr: String = "Syncing..."
    @Published var todayKWhStr: String = "0.0000 kWh"
    
    var timer: Timer?
    let logFileURL = URL(fileURLWithPath: "/Users/Shared/power_history.csv")
    
    // Persistent storage for the day's total energy
    var accumulatedKWh: Double = 0.0
    var lastDateString: String = ""

    init() {
        // Load previous accumulation from computer storage
        accumulatedKWh = UserDefaults.standard.double(forKey: "todayAccumulatedKWh")
        lastDateString = UserDefaults.standard.string(forKey: "lastDateString") ?? ""
        
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        if lastDateString != today {
            accumulatedKWh = 0.0
            lastDateString = today
            UserDefaults.standard.set(accumulatedKWh, forKey: "todayAccumulatedKWh")
            UserDefaults.standard.set(lastDateString, forKey: "lastDateString")
        }
        
        // Ensure CSV log has a header
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            try? "Timestamp, Current_kW, Today_kWh\n".write(to: logFileURL, atomically: true, encoding: .utf8)
        }
        
        updatePowerStatus()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.updatePowerStatus()
        }
    }

    func updatePowerStatus() {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/Applications/Power Monitor.app/Contents/MacOS/Power Monitor")
            task.arguments = ["--noGUI"]
            task.standardOutput = pipe
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines)
                    for line in lines {
                        if line.contains("Current system power") {
                            let parts = line.components(separatedBy: ":")
                            if parts.count >= 2 {
                                let valString = parts[1].trimmingCharacters(in: .whitespaces)
                                if let wValue = Double(valString) {
                                    let kwValue = wValue / 1000.0
                                    
                                    // Math: Energy = Power (kW) * Time (hours). Time is 3 seconds (3/3600 hours).
                                    let kWhAdded = kwValue * (3.0 / 3600.0)
                                    
                                    DispatchQueue.main.async {
                                        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
                                        if self.lastDateString != today {
                                            self.accumulatedKWh = 0.0
                                            self.lastDateString = today
                                        }
                                        
                                        self.accumulatedKWh += kWhAdded
                                        
                                        // Save securely to macOS UserDefaults so it isn't lost if the app closes
                                        UserDefaults.standard.set(self.accumulatedKWh, forKey: "todayAccumulatedKWh")
                                        UserDefaults.standard.set(self.lastDateString, forKey: "lastDateString")
                                        
                                        self.currentKWStr = String(format: "%.3f kW", kwValue)
                                        self.todayKWhStr = String(format: "%.4f kWh", self.accumulatedKWh)
                                        
                                        // Append permanently to the CSV Log File
                                        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
                                        let logLine = "\(timestamp), \(self.currentKWStr), \(self.todayKWhStr)\n"
                                        
                                        if let fileHandle = try? FileHandle(forWritingTo: self.logFileURL) {
                                            fileHandle.seekToEndOfFile()
                                            if let data = logLine.data(using: .utf8) {
                                                fileHandle.write(data)
                                            }
                                            fileHandle.closeFile()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.currentKWStr = "Err"
                }
            }
        }
    }
}
