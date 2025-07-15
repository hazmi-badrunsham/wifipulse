# 📶 WiFi Pulse

**WiFi Pulse** is a Flutter-based mobile application designed for IIUM students to visualize internet speed across campus using geolocation and community-shared heatmaps.

## 🚀 Features

- 📡 **Wi-Fi & Telco Speed Test**  
  Test your download and upload speed with accurate measurements.

- 📍 **Location-Based Results**  
  Automatically detects your current location and associates it with the speed test.

- 🌐 **Campus Heatmap Visualization**  
  View a live heatmap showing download speed performance across campus.

- 🧠 **Smart Caching**  
  Uses Hive to store and display previous results with geolocation names using OpenStreetMap Nominatim reverse geocoding.

- 📜 **Speed Test History**  
  Check your past test results with details like speed, location, network name, and timestamp.

- ☁️ **Supabase Backend**  
  Syncs speed test data in real-time for collective insight across users.

## 🛠️ Built With

- **Flutter** – Cross-platform mobile framework  
- **Supabase** – Backend database for real-time syncing  
- **Hive** – Local key-value data storage  
- **OpenStreetMap (OSM)** – Base map with Nominatim reverse geocoding  
- **Flutter Plugins**:  
  - `flutter_map`  
  - `flutter_map_heatmap`  
  - `flutter_network_speed_test`  
  - `geolocator`, `network_info_plus`, `hive_flutter`, `osm_nominatim`

## 📸 Screenshots


## 📂 Getting Started

### 1. Clone this repo

```bash
git clone https://github.com/hazmi-badrunsham/wifipulse.git
cd wifipulse
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

```bash
flutter run
```

> ⚠️ Make sure you enable location permissions and internet connection on your device.

## 📁 Folder Structure

- `main.dart` – App entry point and navigation
- `heatmap.dart` – Map and heatmap visualization
- `history.dart` – History list with reverse geocoding
- `pubspec.yaml` – Dependencies and assets

## 👤 Author

- **Hazmi Badrunsham**
- **Akif Hakimi**


---

> 🕌 Made for IIUM students to improve campus connectivity experience
