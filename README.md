# PowerMeter

A lightweight macOS Menu Bar application that seamlessly integrates with the SAP Power Monitor engine to display Total System Power (in kW) and track Daily Energy Consumption (in kWh).

## Features
- **Real-time Power (kW):** View exact, system-wide total power draw instantly.
- **Daily Energy (kWh):** Continually calculates the total distance (energy) consumed during the day, automatically resetting at midnight.
- **Persistent Logging:** Safely remembers your daily energy tally even if the app closes. Additionally, every reading is saved permanently to `/Users/Shared/power_history.csv`.
- **Zero Config:** Extracts data gracefully from the existing SAP daemon XPC engine to function seamlessly without requiring Terminal `sudo` passwords.

## Prerequisites
- macOS 13.0 or higher.
- [SAP Power Monitor](https://github.com/SAP/power-monitoring-tool-for-macos) must be installed (this app uses its powerful internal daemon to bypass macOS root permissions).

## How to Build
Simply run the included build script in your terminal:
```bash
./build.sh
```
This will compile the Swift source and generate a native macOS `PowerMeter.app` bundle in the same directory.

## How to Run
Double-click the generated `PowerMeter.app`. It will run silently in your menu bar (top right). You can quit it at any time directly from its menu.
